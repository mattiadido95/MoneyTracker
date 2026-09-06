//
//  MoneyTrackerDesktopTests.swift
//  MoneyTrackerDesktopTests
//
//  Created by Mattia Di Donato on 13/12/25.
//

import Foundation
import SwiftUI
import Testing
@testable import MoneyTrackerDesktop

@MainActor
struct MoneyTrackerDesktopTests {

    private let bundleIdentifier = "tests.MoneyTracker"

    @Test
    func migrationPreservesLegacyAndCreatesStartupSnapshot() throws {
        let baseURL = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: baseURL) }

        let legacyURL = baseURL.appendingPathComponent("spese.json")
        let expenses = [makeExpense(name: "Affitto", amount: 850)]
        let legacyData = try encodeLegacy(expenses)
        try legacyData.write(to: legacyURL)

        let manager = makeManager(baseURL: baseURL)
        let result = try manager.load()

        guard case .migrated(let migrated, let sourceURL) = result else {
            Issue.record("Era atteso il risultato .migrated")
            return
        }

        #expect(migrated.count == 1)
        #expect(migrated.first?.id == expenses.first?.id)
        #expect(sourceURL == legacyURL)
        #expect(try Data(contentsOf: legacyURL) == legacyData)
        #expect(FileManager.default.fileExists(atPath: currentURL(in: baseURL).path))
        #expect(try backupURLs(in: baseURL).count == 1)
    }

    @Test
    func everyLaunchCreatesANewImmutableSnapshot() throws {
        let baseURL = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: baseURL) }

        let manager = makeManager(baseURL: baseURL)
        try manager.save([makeExpense(name: "Spesa", amount: 12.50)])
        let currentBeforeLaunch = try Data(contentsOf: currentURL(in: baseURL))

        _ = try manager.load()
        let firstLaunchBackups = try backupURLs(in: baseURL)
        #expect(firstLaunchBackups.count == 1)

        let firstBackupData = try Data(contentsOf: firstLaunchBackups[0])
        #expect(firstBackupData == currentBeforeLaunch)
        _ = try manager.load()
        let secondLaunchBackups = try backupURLs(in: baseURL)

        #expect(secondLaunchBackups.count == 2)
        #expect(Set(secondLaunchBackups.map(\.lastPathComponent)).count == 2)
        #expect(try Data(contentsOf: firstLaunchBackups[0]) == firstBackupData)
    }

    @Test
    func corruptCurrentIsPreservedAndRecoveredFromPrevious() throws {
        let baseURL = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: baseURL) }

        let manager = makeManager(baseURL: baseURL)
        let firstExpense = makeExpense(name: "Prima", amount: 10)
        let secondExpense = makeExpense(name: "Seconda", amount: 20)
        try manager.save([firstExpense])
        try manager.save([firstExpense, secondExpense])

        let corruptData = Data("{ archivio non valido".utf8)
        try corruptData.write(to: currentURL(in: baseURL), options: .atomic)

        let result = try manager.load()
        guard case .recovered(let recovered, let sourceURL) = result else {
            Issue.record("Era atteso il risultato .recovered")
            return
        }

        #expect(recovered.count == 1)
        #expect(recovered.first?.id == firstExpense.id)
        #expect(sourceURL.lastPathComponent == "expenses.previous.json")
        let snapshotData = try backupURLs(in: baseURL).map { try Data(contentsOf: $0) }
        #expect(snapshotData.contains(corruptData))
    }

    @Test
    func unrecoverableCurrentIsNeverReplacedOrDiscarded() throws {
        let baseURL = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: baseURL) }

        let rootURL = storageRoot(in: baseURL)
        let backupsURL = rootURL.appendingPathComponent("Backups", isDirectory: true)
        try FileManager.default.createDirectory(
            at: backupsURL,
            withIntermediateDirectories: true
        )

        let corruptData = Data("non-json".utf8)
        try corruptData.write(to: currentURL(in: baseURL))
        let manager = makeManager(baseURL: baseURL)

        do {
            _ = try manager.load()
            Issue.record("Il caricamento avrebbe dovuto fallire")
        } catch let error as PersistenceManager.PersistenceError {
            guard case .noRecoverableArchive = error else {
                Issue.record("Era atteso un noRecoverableArchive, ricevuto: \(error)")
                return
            }
        }

        #expect(try Data(contentsOf: currentURL(in: baseURL)) == corruptData)
        #expect(try backupURLs(in: baseURL).count == 1)
    }

    @Test
    func invalidCandidateDoesNotModifyTheLastValidCurrent() throws {
        let baseURL = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: baseURL) }

        let manager = makeManager(baseURL: baseURL)
        try manager.save([makeExpense(name: "Valida", amount: 5)])
        let validCurrent = try Data(contentsOf: currentURL(in: baseURL))

        do {
            try manager.save([makeExpense(name: "Non valida", amount: 0)])
            Issue.record("Il salvataggio avrebbe dovuto rifiutare l'importo nullo")
        } catch let error as PersistenceManager.PersistenceError {
            guard case .validationFailed = error else {
                Issue.record("Era atteso un validationFailed, ricevuto: \(error)")
                return
            }
        }

        #expect(try Data(contentsOf: currentURL(in: baseURL)) == validCurrent)
    }

    private func makeManager(baseURL: URL) -> PersistenceManager {
        PersistenceManager(
            baseApplicationSupportURL: baseURL,
            bundleIdentifier: bundleIdentifier,
            now: { Date(timeIntervalSince1970: 1_788_688_800) }
        )
    }

    private func makeExpense(name: String, amount: Double) -> CategoriaSpesa {
        CategoriaSpesa(
            nome: name,
            importo: amount,
            colore: .blue,
            data: Date(timeIntervalSince1970: 1_700_000_000),
            categoria: "Test"
        )
    }

    private func makeTemporaryDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("MoneyTrackerStorageTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(
            at: url,
            withIntermediateDirectories: true
        )
        return url
    }

    private func storageRoot(in baseURL: URL) -> URL {
        baseURL.appendingPathComponent(bundleIdentifier, isDirectory: true)
    }

    private func currentURL(in baseURL: URL) -> URL {
        storageRoot(in: baseURL).appendingPathComponent("expenses.json")
    }

    private func backupURLs(in baseURL: URL) throws -> [URL] {
        try FileManager.default.contentsOfDirectory(
            at: storageRoot(in: baseURL).appendingPathComponent("Backups", isDirectory: true),
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )
        .filter { $0.pathExtension.lowercased() == "json" }
    }

    private func encodeLegacy(_ expenses: [CategoriaSpesa]) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(expenses)
    }
}
