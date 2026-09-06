//
//  PersistenceManager.swift
//  MoneyTracker
//

import Foundation

/// Gestisce l'archivio locale delle spese e il relativo storico di recovery.
///
/// Lo storage corrente vive in una directory dedicata all'app. Il precedente
/// `Application Support/spese.json` viene importato senza essere modificato o
/// eliminato e resta disponibile come fallback di ultima istanza.
struct PersistenceManager {

    // MARK: - Public result types

    enum LoadResult {
        case firstLaunch
        case loaded([CategoriaSpesa])
        case migrated([CategoriaSpesa], legacyURL: URL)
        case recovered([CategoriaSpesa], sourceURL: URL)

        var expenses: [CategoriaSpesa] {
            switch self {
            case .firstLaunch:
                return []
            case .loaded(let expenses),
                 .migrated(let expenses, _),
                 .recovered(let expenses, _):
                return expenses
            }
        }

        var userNotice: String? {
            switch self {
            case .firstLaunch, .loaded:
                return nil
            case .migrated(let expenses, let legacyURL):
                return "Archivio migrato correttamente: \(expenses.count) spese importate da \(legacyURL.lastPathComponent). Il file originale è stato conservato."
            case .recovered(let expenses, let sourceURL):
                return "Archivio recuperato da \(sourceURL.lastPathComponent): \(expenses.count) spese ripristinate. La copia danneggiata è stata conservata nello storico."
            }
        }
    }

    enum PersistenceError: LocalizedError {
        case startupBackupFailed(path: String, reason: String)
        case invalidArchive(reason: String)
        case unsupportedSchemaVersion(Int)
        case validationFailed(reason: String)
        case noRecoverableArchive(reason: String)
        case currentArchiveChanged(reason: String)
        case previousBackupFailed(reason: String)
        case postWriteValidationFailed(reason: String)

        var errorDescription: String? {
            switch self {
            case .startupBackupFailed(let path, let reason):
                return "Impossibile creare il backup di avvio per \(path). Nessuna modifica è stata abilitata. Dettagli: \(reason)"
            case .invalidArchive(let reason):
                return "Archivio non valido: \(reason)"
            case .unsupportedSchemaVersion(let version):
                return "Versione archivio non supportata: \(version)."
            case .validationFailed(let reason):
                return "Controllo di integrità fallito: \(reason)"
            case .noRecoverableArchive(let reason):
                return "Nessuna copia valida disponibile. I file esistenti sono stati conservati e le scritture sono bloccate. Dettagli: \(reason)"
            case .currentArchiveChanged(let reason):
                return "Il file corrente non è più valido. Il salvataggio è stato annullato per non sovrascriverlo. Dettagli: \(reason)"
            case .previousBackupFailed(let reason):
                return "La copia di sicurezza previous non ha superato la verifica. Il file corrente non è stato sostituito. Dettagli: \(reason)"
            case .postWriteValidationFailed(let reason):
                return "Il file scritto non ha superato la verifica finale. È stato tentato il ripristino della copia precedente. Dettagli: \(reason)"
            }
        }
    }

    // MARK: - Persisted format

    private struct ExpenseStoreDocument: Codable {
        let schemaVersion: Int
        let savedAt: Date
        let records: [CategoriaSpesa]
    }

    private struct StoragePaths {
        let rootDirectory: URL
        let currentFile: URL
        let previousFile: URL
        let backupsDirectory: URL
        let legacyFile: URL
    }

    private static let currentSchemaVersion = 1

    // MARK: - Dependencies

    private let fileManager: FileManager
    private let baseApplicationSupportURL: URL?
    private let bundleIdentifier: String
    private let now: () -> Date
    private let makeUUID: () -> UUID

    static let live = PersistenceManager()

    init(
        fileManager: FileManager = .default,
        baseApplicationSupportURL: URL? = nil,
        bundleIdentifier: String = "app.madd.MoneyTracker",
        now: @escaping () -> Date = Date.init,
        makeUUID: @escaping () -> UUID = UUID.init
    ) {
        self.fileManager = fileManager
        self.baseApplicationSupportURL = baseApplicationSupportURL
        self.bundleIdentifier = bundleIdentifier
        self.now = now
        self.makeUUID = makeUUID
    }

    // MARK: - Load

    /// Carica l'archivio corrente. Prima di decodificarlo crea sempre uno
    /// snapshot immutabile dei byte trovati all'avvio.
    func load() throws -> LoadResult {
        let paths = try makePaths()
        try prepareDirectories(paths)

        if fileManager.fileExists(atPath: paths.currentFile.path) {
            return try loadCurrentArchive(paths)
        }

        if let recovery = try findValidRecovery(in: paths, includeLegacy: false) {
            try writeCurrent(recovery.expenses, paths: paths, rotatePrevious: false)
            return .recovered(recovery.expenses, sourceURL: recovery.url)
        }

        if fileManager.fileExists(atPath: paths.legacyFile.path) {
            return try migrateLegacyArchive(paths)
        }

        return .firstLaunch
    }

    private func loadCurrentArchive(_ paths: StoragePaths) throws -> LoadResult {
        let currentData: Data

        do {
            currentData = try Data(contentsOf: paths.currentFile)
        } catch {
            return try recoverOrThrow(
                paths: paths,
                originalReason: "Lettura di \(paths.currentFile.path) fallita: \(error.localizedDescription)"
            )
        }

        do {
            _ = try createSnapshot(
                data: currentData,
                label: "startup",
                paths: paths
            )
        } catch {
            throw PersistenceError.startupBackupFailed(
                path: paths.currentFile.path,
                reason: error.localizedDescription
            )
        }

        do {
            let expenses = try decodeAndValidate(currentData)
            return .loaded(expenses)
        } catch {
            return try recoverOrThrow(
                paths: paths,
                originalReason: error.localizedDescription
            )
        }
    }

    private func migrateLegacyArchive(_ paths: StoragePaths) throws -> LoadResult {
        let legacyData: Data

        do {
            legacyData = try Data(contentsOf: paths.legacyFile)
        } catch {
            throw PersistenceError.noRecoverableArchive(
                reason: "Lettura del file legacy fallita: \(error.localizedDescription)"
            )
        }

        do {
            _ = try createSnapshot(
                data: legacyData,
                label: "legacy-startup",
                paths: paths
            )
        } catch {
            throw PersistenceError.startupBackupFailed(
                path: paths.legacyFile.path,
                reason: error.localizedDescription
            )
        }

        do {
            let expenses = try decodeAndValidate(legacyData)
            try writeCurrent(expenses, paths: paths, rotatePrevious: false)
            return .migrated(expenses, legacyURL: paths.legacyFile)
        } catch {
            throw PersistenceError.noRecoverableArchive(
                reason: "Il file legacy non è utilizzabile: \(error.localizedDescription)"
            )
        }
    }

    private func recoverOrThrow(
        paths: StoragePaths,
        originalReason: String
    ) throws -> LoadResult {
        guard let recovery = try findValidRecovery(in: paths, includeLegacy: true) else {
            throw PersistenceError.noRecoverableArchive(reason: originalReason)
        }

        try writeCurrent(recovery.expenses, paths: paths, rotatePrevious: false)
        return .recovered(recovery.expenses, sourceURL: recovery.url)
    }

    private func findValidRecovery(
        in paths: StoragePaths,
        includeLegacy: Bool
    ) throws -> (expenses: [CategoriaSpesa], url: URL)? {
        var candidates: [URL] = []

        if fileManager.fileExists(atPath: paths.previousFile.path) {
            candidates.append(paths.previousFile)
        }

        let snapshots = try fileManager.contentsOfDirectory(
            at: paths.backupsDirectory,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        )
        .filter { $0.pathExtension.lowercased() == "json" }
        .sorted { lhs, rhs in
            let lhsDate = (try? lhs.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            let rhsDate = (try? rhs.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            return lhsDate > rhsDate
        }

        candidates.append(contentsOf: snapshots)

        if includeLegacy && fileManager.fileExists(atPath: paths.legacyFile.path) {
            candidates.append(paths.legacyFile)
        }

        for candidate in candidates {
            guard let data = try? Data(contentsOf: candidate),
                  let expenses = try? decodeAndValidate(data) else {
                continue
            }
            return (expenses, candidate)
        }

        return nil
    }

    // MARK: - Save

    /// Salva un nuovo stato soltanto dopo validazione e round-trip del JSON.
    /// Se esiste un current valido, ne conserva i byte in `previous` prima
    /// della sostituzione atomica.
    func save(_ expenses: [CategoriaSpesa]) throws {
        let paths = try makePaths()
        try prepareDirectories(paths)
        try writeCurrent(expenses, paths: paths, rotatePrevious: true)
    }

    private func writeCurrent(
        _ expenses: [CategoriaSpesa],
        paths: StoragePaths,
        rotatePrevious: Bool
    ) throws {
        try validate(expenses)

        let document = ExpenseStoreDocument(
            schemaVersion: Self.currentSchemaVersion,
            savedAt: now(),
            records: expenses
        )
        let encodedData = try makeEncoder().encode(document)

        // Lo staging resta nella stessa directory del current: in questo modo
        // la promozione finale può avvenire con un rename atomico sullo stesso
        // filesystem.
        let stagedFile = paths.rootDirectory.appendingPathComponent(
            ".expenses.pending.\(makeUUID().uuidString).json"
        )
        try encodedData.write(to: stagedFile, options: .atomic)
        defer {
            try? fileManager.removeItem(at: stagedFile)
        }

        // La validazione avviene sui byte riletti dal file temporaneo, non sulla
        // sola rappresentazione in memoria.
        let stagedData = try Data(contentsOf: stagedFile)
        _ = try decodeAndValidate(stagedData)

        var previousData: Data?
        if rotatePrevious && fileManager.fileExists(atPath: paths.currentFile.path) {
            let currentData = try Data(contentsOf: paths.currentFile)

            do {
                _ = try decodeAndValidate(currentData)
            } catch {
                _ = try? createSnapshot(
                    data: currentData,
                    label: "pre-save-invalid",
                    paths: paths
                )
                throw PersistenceError.currentArchiveChanged(reason: error.localizedDescription)
            }

            do {
                try currentData.write(to: paths.previousFile, options: .atomic)
                let copiedPreviousData = try Data(contentsOf: paths.previousFile)
                guard copiedPreviousData == currentData else {
                    throw PersistenceError.previousBackupFailed(
                        reason: "I byte riletti non coincidono con il current."
                    )
                }
                _ = try decodeAndValidate(copiedPreviousData)
                previousData = copiedPreviousData
            } catch let error as PersistenceError {
                throw error
            } catch {
                throw PersistenceError.previousBackupFailed(
                    reason: error.localizedDescription
                )
            }
        }

        if fileManager.fileExists(atPath: paths.currentFile.path) {
            _ = try fileManager.replaceItemAt(
                paths.currentFile,
                withItemAt: stagedFile,
                backupItemName: nil,
                options: []
            )
        } else {
            try fileManager.moveItem(at: stagedFile, to: paths.currentFile)
        }

        do {
            let persistedData = try Data(contentsOf: paths.currentFile)
            _ = try decodeAndValidate(persistedData)
        } catch {
            if let previousData {
                try? previousData.write(to: paths.currentFile, options: .atomic)
            }
            throw PersistenceError.postWriteValidationFailed(
                reason: error.localizedDescription
            )
        }
    }

    // MARK: - Encoding and validation

    private func decodeAndValidate(_ data: Data) throws -> [CategoriaSpesa] {
        let decoder = makeDecoder()

        if let document = try? decoder.decode(ExpenseStoreDocument.self, from: data) {
            guard document.schemaVersion == Self.currentSchemaVersion else {
                throw PersistenceError.unsupportedSchemaVersion(document.schemaVersion)
            }
            try validate(document.records)
            return document.records
        }

        do {
            let legacyExpenses = try decoder.decode([CategoriaSpesa].self, from: data)
            try validate(legacyExpenses)
            return legacyExpenses
        } catch let error as PersistenceError {
            throw error
        } catch {
            throw PersistenceError.invalidArchive(reason: error.localizedDescription)
        }
    }

    private func validate(_ expenses: [CategoriaSpesa]) throws {
        var identifiers = Set<UUID>()

        for (index, expense) in expenses.enumerated() {
            guard identifiers.insert(expense.id).inserted else {
                throw PersistenceError.validationFailed(
                    reason: "UUID duplicato al record \(index + 1): \(expense.id.uuidString)"
                )
            }

            guard !expense.nome.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw PersistenceError.validationFailed(
                    reason: "Nome vuoto al record \(index + 1)."
                )
            }

            guard !expense.categoria.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw PersistenceError.validationFailed(
                    reason: "Categoria vuota al record \(index + 1)."
                )
            }

            guard expense.importo.isFinite && expense.importo > 0 else {
                throw PersistenceError.validationFailed(
                    reason: "Importo non valido al record \(index + 1)."
                )
            }

            guard expense.data.timeIntervalSinceReferenceDate.isFinite else {
                throw PersistenceError.validationFailed(
                    reason: "Data non valida al record \(index + 1)."
                )
            }
        }
    }

    private func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    private func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    // MARK: - Paths and snapshots

    private func makePaths() throws -> StoragePaths {
        let applicationSupport: URL

        if let baseApplicationSupportURL {
            applicationSupport = baseApplicationSupportURL
        } else {
            applicationSupport = try fileManager.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
        }

        let rootDirectory = applicationSupport
            .appendingPathComponent(bundleIdentifier, isDirectory: true)

        return StoragePaths(
            rootDirectory: rootDirectory,
            currentFile: rootDirectory.appendingPathComponent("expenses.json"),
            previousFile: rootDirectory.appendingPathComponent("expenses.previous.json"),
            backupsDirectory: rootDirectory.appendingPathComponent("Backups", isDirectory: true),
            legacyFile: applicationSupport.appendingPathComponent("spese.json")
        )
    }

    private func prepareDirectories(_ paths: StoragePaths) throws {
        try fileManager.createDirectory(
            at: paths.rootDirectory,
            withIntermediateDirectories: true
        )
        try fileManager.createDirectory(
            at: paths.backupsDirectory,
            withIntermediateDirectories: true
        )
    }

    @discardableResult
    private func createSnapshot(
        data: Data,
        label: String,
        paths: StoragePaths
    ) throws -> URL {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss-SSS"

        let timestamp = formatter.string(from: now())
        let identifier = makeUUID().uuidString
        let fileName = "expenses_\(label)_\(timestamp)_\(identifier).json"
        let snapshotURL = paths.backupsDirectory.appendingPathComponent(fileName)

        guard !fileManager.fileExists(atPath: snapshotURL.path) else {
            throw PersistenceError.startupBackupFailed(
                path: snapshotURL.path,
                reason: "Il nome dello snapshot esiste già; nessun backup precedente è stato sovrascritto."
            )
        }

        try data.write(to: snapshotURL, options: .atomic)
        return snapshotURL
    }

    // MARK: - Diagnostics

    func fileInfo() -> String {
        do {
            let paths = try makePaths()
            try prepareDirectories(paths)

            let currentExists = fileManager.fileExists(atPath: paths.currentFile.path)
            let legacyExists = fileManager.fileExists(atPath: paths.legacyFile.path)
            let backupCount = try fileManager.contentsOfDirectory(
                at: paths.backupsDirectory,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            )
            .filter { $0.pathExtension.lowercased() == "json" }
            .count

            let currentSize: Int
            if currentExists,
               let attributes = try? fileManager.attributesOfItem(atPath: paths.currentFile.path),
               let size = attributes[.size] as? NSNumber {
                currentSize = size.intValue
            } else {
                currentSize = 0
            }

            return """
            📄 Archivio corrente: \(paths.currentFile.path)
            📊 Dimensione: \(currentSize) byte
            🗂️ Backup storici: \(backupCount)
            🧰 File legacy conservato: \(legacyExists ? "Sì" : "No")
            ✅ Archivio corrente presente: \(currentExists ? "Sì" : "No")
            """
        } catch {
            return "❌ Impossibile leggere le informazioni storage: \(error.localizedDescription)"
        }
    }
}
