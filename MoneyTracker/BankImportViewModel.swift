//
//  BankImportViewModel.swift
//  MoneyTracker
//
//  Created by Assistant on 14/12/25.
//

/*
 VIEWMODEL - Bank Import ViewModel
 
 Responsabilità: Gestire logica e stato dell'import bancario
 
 DESIGN:
 • ObservableObject per SwiftUI
 • Async/await per ETL pipeline
 • Stato reattivo con @Published
 • Separazione logica da UI
 • Error handling completo
 
 UTILIZZO:
 @StateObject private var viewModel = BankImportViewModel()
 
 viewModel.importFile(from: fileURL)
*/

import Foundation
import SwiftUI
import Combine

// MARK: - Import State

/// Stato del processo di import
enum BankImportState: Equatable {
    case idle
    case processing
    case success(BankImport)
    case failure(String)
    
    static func == (lhs: BankImportState, rhs: BankImportState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle):
            return true
        case (.processing, .processing):
            return true
        case (.success(let lhsImport), .success(let rhsImport)):
            return lhsImport.id == rhsImport.id
        case (.failure(let lhsError), .failure(let rhsError)):
            return lhsError == rhsError
        default:
            return false
        }
    }
    
    var isProcessing: Bool {
        if case .processing = self { return true }
        return false
    }
    
    var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }
    
    var isFailed: Bool {
        if case .failure = self { return true }
        return false
    }
}

// MARK: - BankImportViewModel

@MainActor
class BankImportViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Stato corrente dell'import
    @Published var importState: BankImportState = .idle
    
    /// BankImport risultante (se successo)
    @Published var bankImport: BankImport?
    
    /// Risultato pipeline ETL completo
    @Published var pipelineResult: ETLPipelineResult?
    
    /// Transazioni per preview
    @Published var previewTransactions: [BankTransaction] = []
    
    /// Mostra alert errore
    @Published var showErrorAlert: Bool = false
    
    /// Messaggio errore per alert
    @Published var errorMessage: String = ""
    
    /// Progress (0.0 - 1.0)
    @Published var importProgress: Double = 0.0
    
    /// Messaggio progress corrente
    @Published var progressMessage: String = ""
    
    // MARK: - Private Properties
    
    /// Pipeline ETL configurato
    private var pipeline: BankETLPipeline
    
    /// File URL corrente
    private var currentFileURL: URL?
    
    // MARK: - Configuration
    
    /// Nome banca per transformer
    var bankName: String {
        didSet {
            // Ricrea pipeline quando cambia banca
            pipeline = BankETLPipeline.generic(
                bankName: bankName,
                configuration: pipelineConfiguration
            )
        }
    }
    
    /// Configurazione pipeline
    var pipelineConfiguration: ETLPipelineConfiguration
    
    /// Mapping colonne
    var columnMapping: BankColumnMapping {
        didSet {
            pipeline.columnMapping = columnMapping
        }
    }
    
    // MARK: - Initialization
    
    init(
        bankName: String = "Intesa Sanpaolo",
        pipelineConfiguration: ETLPipelineConfiguration = .default,
        columnMapping: BankColumnMapping = .default
    ) {
        self.bankName = bankName
        self.pipelineConfiguration = pipelineConfiguration
        self.columnMapping = columnMapping
        
        // Crea pipeline iniziale
        self.pipeline = BankETLPipeline.generic(
            bankName: bankName,
            columnMapping: columnMapping,
            configuration: pipelineConfiguration
        )
    }
    
    // MARK: - Public Methods
    
    /// Seleziona automaticamente la pipeline corretta in base al file
    private func selectPipeline(for fileURL: URL) {
        let ext = fileURL.pathExtension.lowercased()
        if ext == "xls" {
            // File .xls → usa sempre BPER (unico formato .xls supportato)
            pipeline = BankETLPipeline.bper(configuration: pipelineConfiguration)
        } else {
            // File .xlsx → mantieni pipeline generica o quella già configurata
            pipeline = BankETLPipeline.generic(
                bankName: bankName,
                columnMapping: columnMapping,
                configuration: pipelineConfiguration
            )
        }
    }

    /// Importa file estratto conto
    /// - Parameter fileURL: URL del file XLS o XLSX
    func importFile(from fileURL: URL) async {
        currentFileURL = fileURL
        importState = .processing
        importProgress = 0.0
        progressMessage = "Avvio import..."

        // Sceglie la pipeline in base al formato file
        selectPipeline(for: fileURL)

        do {
            // Simula progress (ETL non ha progress reale)
            updateProgress(0.2, message: "Lettura file...")
            
            // Esegui ETL pipeline
            let result = try await pipeline.process(fileURL: fileURL)
            
            updateProgress(0.8, message: "Validazione completata...")
            
            // Salva risultato
            pipelineResult = result
            
            if result.isSuccess, let importedData = result.bankImport {
                bankImport = importedData
                previewTransactions = Array(importedData.transactions.prefix(10)) // Prime 10
                importState = .success(importedData)
                updateProgress(1.0, message: "Import completato!")
                
                print("✅ Import completato con successo")
                print(result.report)
            } else {
                let errorMsg = result.error?.localizedDescription ?? "Errore sconosciuto"
                importState = .failure(errorMsg)
                errorMessage = errorMsg
                showErrorAlert = true
                
                print("❌ Import fallito")
                print(result.report)
            }
            
        } catch {
            let errorMsg = error.localizedDescription
            importState = .failure(errorMsg)
            errorMessage = errorMsg
            showErrorAlert = true
            
            print("❌ Import fallito: \(errorMsg)")
        }
    }
    
    /// Reset stato
    func reset() {
        importState = .idle
        bankImport = nil
        pipelineResult = nil
        previewTransactions = []
        importProgress = 0.0
        progressMessage = ""
        currentFileURL = nil
    }
    
    /// Esporta import corrente come JSON
    func exportToJSON() throws -> BankImportExportResult? {
        guard let bankImport = bankImport else { return nil }
        
        let exporter = BankImportExporter()
        return try exporter.export(bankImport)
    }
    
    /// Ottieni report testuale
    func getReport() -> String? {
        return pipelineResult?.report
    }
    
    /// Ottieni summary breve
    func getSummary() -> String? {
        return pipelineResult?.summary
    }
    
    // MARK: - Private Methods
    
    private func updateProgress(_ value: Double, message: String) {
        importProgress = value
        progressMessage = message
    }
}

// MARK: - Computed Properties

extension BankImportViewModel {
    /// Statistiche per UI
    var statistics: ImportStatistics? {
        guard let result = pipelineResult else { return nil }
        
        return ImportStatistics(
            extractedRows: result.extractedRowCount,
            transformedTransactions: result.transformedTransactionCount,
            validTransactions: result.validTransactionCount,
            rejectedTransactions: result.rejectedTransactionCount,
            successRate: result.overallSuccessRate,
            processingTime: result.processingTime
        )
    }
    
    /// Ha transazioni da mostrare
    var hasTransactions: Bool {
        !previewTransactions.isEmpty
    }
    
    /// Può esportare
    var canExport: Bool {
        bankImport != nil
    }
}

// MARK: - Import Statistics

struct ImportStatistics {
    let extractedRows: Int
    let transformedTransactions: Int
    let validTransactions: Int
    let rejectedTransactions: Int
    let successRate: Double
    let processingTime: TimeInterval
    
    var formattedSuccessRate: String {
        String(format: "%.1f%%", successRate)
    }
    
    var formattedProcessingTime: String {
        String(format: "%.2f secondi", processingTime)
    }
}

// MARK: - Testing Helpers

#if DEBUG
extension BankImportViewModel {
    /// ViewModel per preview
    static var preview: BankImportViewModel {
        let vm = BankImportViewModel()
        vm.bankImport = .sample
        vm.previewTransactions = BankTransaction.samples
        vm.importState = .success(.sample)
        return vm
    }
    
    /// ViewModel con errore
    static var previewError: BankImportViewModel {
        let vm = BankImportViewModel()
        vm.importState = .failure("File non valido")
        vm.errorMessage = "File non valido"
        return vm
    }
}
#endif
