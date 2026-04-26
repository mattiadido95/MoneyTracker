//
//  BankImportExporter.swift
//  MoneyTracker
//
//  Created by Assistant on 14/12/25.
//

/*
 SERVICE - Bank Import Exporter
 
 Responsabilità: Esportare BankImport in formato JSON
 
 DESIGN:
 • Serializzazione JSON pretty-printed
 • Date in formato ISO8601
 • Nomi file intelligenti basati su data/banca
 • Gestione directory e permessi
 • Error handling robusto
 
 UTILIZZO:
 let exporter = BankImportExporter()
 let fileURL = try exporter.export(bankImport)
 print("Esportato in: \(fileURL.path)")
*/

import Foundation

// MARK: - Export Configuration

/// Configurazione per l'esportazione
struct BankImportExportConfiguration {
    /// Directory dove salvare i file
    var outputDirectory: URL
    
    /// Formato nome file
    var fileNamingStrategy: FileNamingStrategy
    
    /// Sovrascrive file esistenti
    var overwriteExisting: Bool
    
    /// Pretty print JSON
    var prettyPrint: Bool
    
    /// Formato date
    var dateFormat: DateFormat
    
    /// Default configuration (salva in Documents)
    static var `default`: BankImportExportConfiguration {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let bankImportsURL = documentsURL.appendingPathComponent("BankImports", isDirectory: true)
        
        return BankImportExportConfiguration(
            outputDirectory: bankImportsURL,
            fileNamingStrategy: .bankAndDate,
            overwriteExisting: false,
            prettyPrint: true,
            dateFormat: .iso8601
        )
    }
    
    /// Configurazione per temp directory
    static var temporary: BankImportExportConfiguration {
        var config = BankImportExportConfiguration.default
        config.outputDirectory = FileManager.default.temporaryDirectory
        config.overwriteExisting = true
        return config
    }
}

// MARK: - File Naming Strategy

/// Strategia per nominare i file esportati
enum FileNamingStrategy {
    /// Usa nome banca e data (es: "IntesaSanpaolo_2024-12-14.json")
    case bankAndDate
    
    /// Usa UUID (es: "123e4567-e89b-12d3-a456-426614174000.json")
    case uuid
    
    /// Usa timestamp (es: "20241214_153045.json")
    case timestamp
    
    /// Nome custom con template (usa placeholder: {bank}, {date}, {uuid})
    case custom(String)
    
    /// Genera nome file per BankImport
    func fileName(for bankImport: BankImport) -> String {
        switch self {
        case .bankAndDate:
            let bankName = sanitize(bankImport.bankName)
            let dateStr = formatDate(bankImport.importedAt, format: "yyyy-MM-dd")
            return "\(bankName)_\(dateStr).json"
            
        case .uuid:
            return "\(bankImport.id.uuidString).json"
            
        case .timestamp:
            let timestamp = formatDate(bankImport.importedAt, format: "yyyyMMdd_HHmmss")
            return "\(timestamp).json"
            
        case .custom(let template):
            var result = template
            result = result.replacingOccurrences(of: "{bank}", with: sanitize(bankImport.bankName))
            result = result.replacingOccurrences(of: "{date}", with: formatDate(bankImport.importedAt, format: "yyyy-MM-dd"))
            result = result.replacingOccurrences(of: "{uuid}", with: bankImport.id.uuidString)
            
            if !result.hasSuffix(".json") {
                result += ".json"
            }
            
            return result
        }
    }
    
    private func sanitize(_ string: String) -> String {
        // Rimuovi caratteri non validi per nomi file
        let invalidCharacters = CharacterSet(charactersIn: ":/\\?%*|\"<>")
        return string
            .components(separatedBy: invalidCharacters)
            .joined(separator: "_")
            .replacingOccurrences(of: " ", with: "_")
    }
    
    private func formatDate(_ date: Date, format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        return formatter.string(from: date)
    }
}

// MARK: - Date Format

/// Formato date per export
enum DateFormat {
    /// ISO8601 completo (es: "2024-12-14T15:30:45.123Z")
    case iso8601
    
    /// ISO8601 senza fractional seconds
    case iso8601Simple
    
    /// Custom formatter
    case custom(DateFormatter)
}

// MARK: - Export Result

/// Risultato dell'esportazione
struct BankImportExportResult {
    /// URL del file esportato
    let fileURL: URL
    
    /// Dimensione file in bytes
    let fileSize: Int64
    
    /// Tempo di esportazione
    let exportTime: TimeInterval
    
    /// Numero transazioni esportate
    let transactionCount: Int
    
    /// Summary leggibile
    var summary: String {
        let sizeFormatted = ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
        return """
        ✅ Export completato
        📁 File: \(fileURL.lastPathComponent)
        📊 Transazioni: \(transactionCount)
        💾 Dimensione: \(sizeFormatted)
        ⏱️  Tempo: \(String(format: "%.2f", exportTime)) secondi
        📍 Path: \(fileURL.path)
        """
    }
}

// MARK: - Export Errors

enum BankImportExportError: LocalizedError {
    case directoryCreationFailed(path: String, underlyingError: Error)
    case fileAlreadyExists(path: String)
    case encodingFailed(reason: String)
    case writeFailed(path: String, underlyingError: Error)
    case invalidConfiguration(reason: String)
    case permissionDenied(path: String)
    
    var errorDescription: String? {
        switch self {
        case .directoryCreationFailed(let path, let error):
            return "Impossibile creare directory '\(path)': \(error.localizedDescription)"
        case .fileAlreadyExists(let path):
            return "Il file '\(path)' esiste già"
        case .encodingFailed(let reason):
            return "Encoding JSON fallito: \(reason)"
        case .writeFailed(let path, let error):
            return "Scrittura file '\(path)' fallita: \(error.localizedDescription)"
        case .invalidConfiguration(let reason):
            return "Configurazione non valida: \(reason)"
        case .permissionDenied(let path):
            return "Permesso negato per scrivere in '\(path)'"
        }
    }
}

// MARK: - BankImportExporter

/// Servizio per esportare BankImport in formato JSON
class BankImportExporter {
    
    // MARK: - Properties
    
    /// Configurazione esportazione
    var configuration: BankImportExportConfiguration
    
    /// File manager
    private let fileManager: FileManager
    
    // MARK: - Initialization
    
    init(
        configuration: BankImportExportConfiguration = .default,
        fileManager: FileManager = .default
    ) {
        self.configuration = configuration
        self.fileManager = fileManager
    }
    
    // MARK: - Export Methods
    
    /// Esporta BankImport in file JSON
    /// - Parameter bankImport: BankImport da esportare
    /// - Returns: Risultato esportazione con URL file
    /// - Throws: BankImportExportError se fallisce
    func export(_ bankImport: BankImport) throws -> BankImportExportResult {
        let startTime = Date()
        
        // 1. Prepara directory
        try prepareOutputDirectory()
        
        // 2. Genera nome file
        let fileName = configuration.fileNamingStrategy.fileName(for: bankImport)
        let fileURL = configuration.outputDirectory.appendingPathComponent(fileName)
        
        // 3. Verifica se file esiste
        if fileManager.fileExists(atPath: fileURL.path) && !configuration.overwriteExisting {
            throw BankImportExportError.fileAlreadyExists(path: fileURL.path)
        }
        
        // 4. Encode JSON
        let jsonData = try encodeToJSON(bankImport)
        
        // 5. Scrivi file
        try writeToFile(jsonData, at: fileURL)
        
        // 6. Verifica dimensione file
        let fileSize = try getFileSize(at: fileURL)
        
        let exportTime = Date().timeIntervalSince(startTime)
        
        return BankImportExportResult(
            fileURL: fileURL,
            fileSize: fileSize,
            exportTime: exportTime,
            transactionCount: bankImport.transactionCount
        )
    }
    
    /// Esporta multipli BankImport
    /// - Parameter bankImports: Array di BankImport da esportare
    /// - Returns: Array di risultati
    /// - Throws: Se uno degli export fallisce
    func exportMultiple(_ bankImports: [BankImport]) throws -> [BankImportExportResult] {
        var results: [BankImportExportResult] = []
        
        for bankImport in bankImports {
            let result = try export(bankImport)
            results.append(result)
        }
        
        return results
    }
    
    /// Esporta e restituisce JSON come stringa (senza scrivere file)
    /// - Parameter bankImport: BankImport da esportare
    /// - Returns: Stringa JSON
    /// - Throws: Se encoding fallisce
    func exportToString(_ bankImport: BankImport) throws -> String {
        let jsonData = try encodeToJSON(bankImport)
        
        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            throw BankImportExportError.encodingFailed(reason: "Impossibile convertire Data in String")
        }
        
        return jsonString
    }
    
    /// Esporta e restituisce Data (senza scrivere file)
    /// - Parameter bankImport: BankImport da esportare
    /// - Returns: Data JSON
    /// - Throws: Se encoding fallisce
    func exportToData(_ bankImport: BankImport) throws -> Data {
        return try encodeToJSON(bankImport)
    }
    
    // MARK: - Private Methods
    
    private func prepareOutputDirectory() throws {
        let path = configuration.outputDirectory.path
        
        // Verifica se directory esiste
        var isDirectory: ObjCBool = false
        let exists = fileManager.fileExists(atPath: path, isDirectory: &isDirectory)
        
        if exists && !isDirectory.boolValue {
            throw BankImportExportError.invalidConfiguration(
                reason: "Il path '\(path)' esiste ma non è una directory"
            )
        }
        
        if !exists {
            // Crea directory
            do {
                try fileManager.createDirectory(
                    at: configuration.outputDirectory,
                    withIntermediateDirectories: true,
                    attributes: nil
                )
            } catch {
                throw BankImportExportError.directoryCreationFailed(
                    path: path,
                    underlyingError: error
                )
            }
        }
        
        // Verifica permessi di scrittura
        if !fileManager.isWritableFile(atPath: path) {
            throw BankImportExportError.permissionDenied(path: path)
        }
    }
    
    private func encodeToJSON(_ bankImport: BankImport) throws -> Data {
        let encoder = JSONEncoder()
        
        // Configura encoder
        if configuration.prettyPrint {
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        }
        
        // Configura date encoding
        switch configuration.dateFormat {
        case .iso8601:
            encoder.dateEncodingStrategy = .iso8601
            
        case .iso8601Simple:
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime]
            encoder.dateEncodingStrategy = .formatted(formatter as! DateFormatter)
            
        case .custom(let formatter):
            encoder.dateEncodingStrategy = .formatted(formatter)
        }
        
        do {
            return try encoder.encode(bankImport)
        } catch {
            throw BankImportExportError.encodingFailed(
                reason: error.localizedDescription
            )
        }
    }
    
    private func writeToFile(_ data: Data, at url: URL) throws {
        do {
            try data.write(to: url, options: .atomic)
        } catch {
            throw BankImportExportError.writeFailed(
                path: url.path,
                underlyingError: error
            )
        }
    }
    
    private func getFileSize(at url: URL) throws -> Int64 {
        let attributes = try fileManager.attributesOfItem(atPath: url.path)
        return attributes[.size] as? Int64 ?? 0
    }
    
    // MARK: - Utility Methods
    
    /// Lista tutti i file JSON nella output directory
    /// - Returns: Array di URL dei file JSON
    func listExportedFiles() throws -> [URL] {
        let path = configuration.outputDirectory.path
        
        guard fileManager.fileExists(atPath: path) else {
            return []
        }
        
        let contents = try fileManager.contentsOfDirectory(
            at: configuration.outputDirectory,
            includingPropertiesForKeys: [.fileSizeKey, .creationDateKey],
            options: [.skipsHiddenFiles]
        )
        
        return contents.filter { $0.pathExtension == "json" }
    }
    
    /// Elimina un file esportato
    /// - Parameter fileURL: URL del file da eliminare
    func deleteExportedFile(at fileURL: URL) throws {
        try fileManager.removeItem(at: fileURL)
    }
    
    /// Elimina tutti i file esportati nella directory
    func deleteAllExportedFiles() throws {
        let files = try listExportedFiles()
        
        for file in files {
            try fileManager.removeItem(at: file)
        }
    }
}

// MARK: - Convenience Extensions

extension BankImportExporter {
    /// Esporta in directory temporanea
    static func exportToTemp(_ bankImport: BankImport) throws -> BankImportExportResult {
        let exporter = BankImportExporter(configuration: .temporary)
        return try exporter.export(bankImport)
    }
    
    /// Esporta con nome file custom
    static func exportWithCustomName(
        _ bankImport: BankImport,
        fileName: String,
        outputDirectory: URL? = nil
    ) throws -> BankImportExportResult {
        var config = BankImportExportConfiguration.default
        
        if let directory = outputDirectory {
            config.outputDirectory = directory
        }
        
        config.fileNamingStrategy = .custom(fileName)
        
        let exporter = BankImportExporter(configuration: config)
        return try exporter.export(bankImport)
    }
}

// MARK: - BankImport Extension

extension BankImport {
    /// Esporta self come JSON file
    /// - Parameter configuration: Configurazione export (opzionale)
    /// - Returns: Risultato export con URL
    func exportToJSON(configuration: BankImportExportConfiguration = .default) throws -> BankImportExportResult {
        let exporter = BankImportExporter(configuration: configuration)
        return try exporter.export(self)
    }
    
    /// Esporta self come stringa JSON
    /// - Returns: Stringa JSON pretty-printed
    func toJSONString() throws -> String {
        let exporter = BankImportExporter()
        return try exporter.exportToString(self)
    }
}

// MARK: - Testing Helpers

#if DEBUG
extension BankImportExporter {
    /// Exporter per testing (usa temp directory)
    static var mock: BankImportExporter {
        BankImportExporter(configuration: .temporary)
    }
}

extension BankImportExportConfiguration {
    /// Configurazione per testing
    static var test: BankImportExportConfiguration {
        var config = BankImportExportConfiguration.temporary
        config.prettyPrint = true
        config.overwriteExisting = true
        return config
    }
}
#endif

// MARK: - Example Usage (Documentation)

/*
 ESEMPI D'USO:
 
 // 1. Export basico
 let exporter = BankImportExporter()
 let result = try exporter.export(bankImport)
 print(result.summary)
 
 // 2. Export con configurazione custom
 var config = BankImportExportConfiguration.default
 config.fileNamingStrategy = .timestamp
 config.prettyPrint = true
 
 let exporter = BankImportExporter(configuration: config)
 let result = try exporter.export(bankImport)
 
 // 3. Export rapido in temp
 let result = try BankImportExporter.exportToTemp(bankImport)
 
 // 4. Export come stringa (senza file)
 let jsonString = try bankImport.toJSONString()
 print(jsonString)
 
 // 5. Export multipli
 let results = try exporter.exportMultiple([import1, import2, import3])
 
 // 6. Lista file esportati
 let files = try exporter.listExportedFiles()
 for file in files {
     print("📄 \(file.lastPathComponent)")
 }
 
 // 7. Elimina vecchi export
 try exporter.deleteAllExportedFiles()
 */
