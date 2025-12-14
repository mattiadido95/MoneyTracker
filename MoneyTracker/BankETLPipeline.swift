//
//  BankETLPipeline.swift
//  MoneyTracker
//
//  Created by Assistant on 14/12/25.
//

/*
 COORDINATOR - Bank ETL Pipeline
 
 Responsabilità: Orchestrare l'intero processo ETL (Extract → Transform → Validate → Load)
 
 DESIGN:
 • Coordina extractor, transformer e validator
 • Gestisce errori e logging
 • Produce BankImport finale
 • Report dettagliato processo
 • Zero UI logic, pura business logic
 
 UTILIZZO:
 let pipeline = BankETLPipeline(
     extractor: XLSXBankExtractor(),
     transformer: DefaultBankTransformer(bankName: "Intesa Sanpaolo"),
     validator: DefaultBankValidator()
 )
 
 let result = try await pipeline.process(fileURL: selectedFile)
 print(result.report)
*/

import Foundation

// MARK: - ETL Pipeline Result

/// Risultato completo del processo ETL
struct ETLPipelineResult {
    
    // MARK: - Properties
    
    /// BankImport finale (se successo)
    let bankImport: BankImport?
    
    /// Successo del processo
    let isSuccess: Bool
    
    /// Fase in cui è avvenuto eventuale errore
    let failedPhase: ETLPhase?
    
    /// Errore principale (se fallito)
    let error: Error?
    
    // MARK: - Statistics
    
    /// Numero righe estratte dal file
    let extractedRowCount: Int
    
    /// Numero transazioni trasformate
    let transformedTransactionCount: Int
    
    /// Numero transazioni valide
    let validTransactionCount: Int
    
    /// Numero transazioni scartate
    let rejectedTransactionCount: Int
    
    /// Errori non bloccanti incontrati
    let warnings: [String]
    
    /// Dettagli errori validazione
    let validationErrors: [ValidationError]
    
    /// Tempo di elaborazione
    let processingTime: TimeInterval
    
    // MARK: - Computed Properties
    
    /// Percentuale successo trasformazione
    var transformSuccessRate: Double {
        guard extractedRowCount > 0 else { return 0 }
        return Double(transformedTransactionCount) / Double(extractedRowCount) * 100.0
    }
    
    /// Percentuale successo validazione
    var validationSuccessRate: Double {
        guard transformedTransactionCount > 0 else { return 0 }
        return Double(validTransactionCount) / Double(transformedTransactionCount) * 100.0
    }
    
    /// Percentuale successo totale (end-to-end)
    var overallSuccessRate: Double {
        guard extractedRowCount > 0 else { return 0 }
        return Double(validTransactionCount) / Double(extractedRowCount) * 100.0
    }
    
    /// Report testuale dettagliato
    var report: String {
        var lines: [String] = []
        
        lines.append("=" * 50)
        lines.append("📊 REPORT ETL PIPELINE")
        lines.append("=" * 50)
        
        // Status
        if isSuccess {
            lines.append("✅ Status: SUCCESS")
        } else {
            lines.append("❌ Status: FAILED")
            if let phase = failedPhase {
                lines.append("   Fase fallita: \(phase.rawValue)")
            }
            if let error = error {
                lines.append("   Errore: \(error.localizedDescription)")
            }
        }
        
        lines.append("")
        
        // Statistics
        lines.append("📈 STATISTICHE")
        lines.append("-" * 50)
        lines.append("Righe estratte:        \(extractedRowCount)")
        lines.append("Transazioni trasform.: \(transformedTransactionCount)")
        lines.append("Transazioni valide:    \(validTransactionCount)")
        lines.append("Transazioni scartate:  \(rejectedTransactionCount)")
        lines.append("")
        lines.append(String(format: "Tasso trasformazione:  %.1f%%", transformSuccessRate))
        lines.append(String(format: "Tasso validazione:     %.1f%%", validationSuccessRate))
        lines.append(String(format: "Tasso successo totale: %.1f%%", overallSuccessRate))
        lines.append("")
        lines.append(String(format: "Tempo elaborazione:    %.2f secondi", processingTime))
        
        // Warnings
        if !warnings.isEmpty {
            lines.append("")
            lines.append("⚠️  WARNING (\(warnings.count))")
            lines.append("-" * 50)
            for (index, warning) in warnings.prefix(5).enumerated() {
                lines.append("  \(index + 1). \(warning)")
            }
            if warnings.count > 5 {
                lines.append("  ... e altri \(warnings.count - 5) warning")
            }
        }
        
        // Validation Errors
        if !validationErrors.isEmpty {
            lines.append("")
            lines.append("❌ ERRORI VALIDAZIONE (\(validationErrors.count))")
            lines.append("-" * 50)
            for (index, error) in validationErrors.prefix(5).enumerated() {
                let rowInfo = error.transactionIndex.map { " [riga \($0)]" } ?? ""
                lines.append("  \(index + 1).\(rowInfo) \(error.message)")
            }
            if validationErrors.count > 5 {
                lines.append("  ... e altri \(validationErrors.count - 5) errori")
            }
        }
        
        // BankImport Summary
        if let bankImport = bankImport {
            lines.append("")
            lines.append("📦 IMPORT CREATO")
            lines.append("-" * 50)
            lines.append("Banca: \(bankImport.bankName)")
            lines.append("File: \(bankImport.sourceFileName)")
            lines.append("Transazioni: \(bankImport.transactionCount)")
            lines.append(String(format: "Totale entrate: €%.2f", bankImport.totalIncome))
            lines.append(String(format: "Totale uscite:  €%.2f", bankImport.totalExpenses))
            lines.append(String(format: "Saldo netto:    €%.2f", bankImport.netBalance))
        }
        
        lines.append("=" * 50)
        
        return lines.joined(separator: "\n")
    }
    
    /// Summary breve per logging
    var summary: String {
        if isSuccess {
            return "✅ ETL completato: \(validTransactionCount)/\(extractedRowCount) transazioni valide (\(String(format: "%.1f%%", overallSuccessRate)))"
        } else {
            return "❌ ETL fallito in fase \(failedPhase?.rawValue ?? "unknown"): \(error?.localizedDescription ?? "unknown error")"
        }
    }
}

// MARK: - ETL Phase

/// Fasi del processo ETL
enum ETLPhase: String {
    case extract = "EXTRACT"
    case transform = "TRANSFORM"
    case validate = "VALIDATE"
    case load = "LOAD"
}

// MARK: - ETL Pipeline Configuration

/// Configurazione del pipeline ETL
struct ETLPipelineConfiguration {
    /// Percentuale minima di successo trasformazione (default 80%)
    var minimumTransformSuccessRate: Double = 80.0
    
    /// Percentuale minima di successo validazione (default 70%)
    var minimumValidationSuccessRate: Double = 70.0
    
    /// Abilita logging dettagliato
    var verboseLogging: Bool = true
    
    /// Includi warning nel risultato
    var includeWarnings: Bool = true
    
    /// Salta righe vuote durante estrazione
    var skipEmptyRows: Bool = true
    
    /// Default configuration
    static var `default`: ETLPipelineConfiguration {
        ETLPipelineConfiguration()
    }
    
    /// Strict configuration (soglie più alte)
    static var strict: ETLPipelineConfiguration {
        ETLPipelineConfiguration(
            minimumTransformSuccessRate: 95.0,
            minimumValidationSuccessRate: 95.0,
            verboseLogging: true,
            includeWarnings: true
        )
    }
    
    /// Lenient configuration (soglie più basse)
    static var lenient: ETLPipelineConfiguration {
        ETLPipelineConfiguration(
            minimumTransformSuccessRate: 50.0,
            minimumValidationSuccessRate: 50.0,
            verboseLogging: false,
            includeWarnings: false
        )
    }
}

// MARK: - Bank ETL Pipeline

/// Coordinatore del processo ETL bancario
class BankETLPipeline {
    
    // MARK: - Properties
    
    /// Extractor per lettura file
    private let extractor: BankExtractor
    
    /// Transformer per conversione dati
    private let transformer: DefaultBankTransformer
    
    /// Validator per validazione transazioni
    private let validator: DefaultBankValidator
    
    /// Configurazione pipeline
    var configuration: ETLPipelineConfiguration
    
    /// Mapping colonne per transformer
    var columnMapping: BankColumnMapping
    
    // MARK: - Initialization
    
    init(
        extractor: BankExtractor,
        transformer: DefaultBankTransformer,
        validator: DefaultBankValidator,
        configuration: ETLPipelineConfiguration = .default,
        columnMapping: BankColumnMapping = .default
    ) {
        self.extractor = extractor
        self.transformer = transformer
        self.validator = validator
        self.configuration = configuration
        self.columnMapping = columnMapping
    }
    
    // MARK: - Pipeline Execution
    
    /// Esegue l'intero processo ETL
    /// - Parameter fileURL: URL del file da processare
    /// - Returns: Risultato completo del processo
    func process(fileURL: URL) async throws -> ETLPipelineResult {
        let startTime = Date()
        
        log("🚀 Avvio ETL Pipeline per file: \(fileURL.lastPathComponent)")
        
        var extractedRows: [RawBankRow] = []
        var transformedTransactions: [BankTransaction] = []
        var validationResult: BankValidationResult?
        var warnings: [String] = []
        
        do {
            // ==============================
            // PHASE 1: EXTRACT
            // ==============================
            log("📥 FASE 1: EXTRACT")
            
            guard let xlsxExtractor = extractor as? XLSXBankExtractor else {
                throw BankImportError.invalidFileFormat
            }
            
            extractedRows = try await xlsxExtractor.extractRows(from: fileURL)
            
            log("   ✅ Estratte \(extractedRows.count) righe")
            
            guard !extractedRows.isEmpty else {
                throw BankImportError.emptyFile
            }
            
            // ==============================
            // PHASE 2: TRANSFORM
            // ==============================
            log("🔄 FASE 2: TRANSFORM")
            
            var transformErrors: [String] = []
            
            for (index, row) in extractedRows.enumerated() {
                do {
                    let transaction = try transformer.transformRow(row, columnMapping: columnMapping)
                    transformedTransactions.append(transaction)
                } catch {
                    let errorMsg = "Riga \(row.rowIndex): \(error.localizedDescription)"
                    transformErrors.append(errorMsg)
                    if configuration.verboseLogging {
                        log("   ⚠️  \(errorMsg)")
                    }
                }
            }
            
            log("   ✅ Trasformate \(transformedTransactions.count)/\(extractedRows.count) transazioni")
            
            let transformRate = Double(transformedTransactions.count) / Double(extractedRows.count) * 100.0
            log(String(format: "   📊 Tasso successo: %.1f%%", transformRate))
            
            // Verifica soglia minima trasformazione
            if transformRate < configuration.minimumTransformSuccessRate {
                let message = String(format: "Tasso trasformazione troppo basso: %.1f%% (minimo: %.1f%%)", 
                                   transformRate, 
                                   configuration.minimumTransformSuccessRate)
                warnings.append(message)
                log("   ⚠️  \(message)")
            }
            
            guard !transformedTransactions.isEmpty else {
                throw BankImportError.parsingFailed(details: "Nessuna transazione valida dopo trasformazione")
            }
            
            // ==============================
            // PHASE 3: VALIDATE
            // ==============================
            log("✓ FASE 3: VALIDATE")
            
            validationResult = validator.validateDetailed(transformedTransactions)
            
            log("   ✅ Valide: \(validationResult!.validCount)/\(transformedTransactions.count)")
            log("   ❌ Invalide: \(validationResult!.invalidCount)")
            
            if configuration.includeWarnings && !validationResult!.warnings.isEmpty {
                log("   ⚠️  Warning: \(validationResult!.warnings.count)")
            }
            
            let validationRate = validationResult!.successRate
            log(String(format: "   📊 Tasso successo: %.1f%%", validationRate))
            
            // Verifica soglia minima validazione
            if validationRate < configuration.minimumValidationSuccessRate {
                let message = String(format: "Tasso validazione troppo basso: %.1f%% (minimo: %.1f%%)", 
                                   validationRate, 
                                   configuration.minimumValidationSuccessRate)
                warnings.append(message)
                log("   ⚠️  \(message)")
            }
            
            guard !validationResult!.validTransactions.isEmpty else {
                throw BankImportError.parsingFailed(details: "Nessuna transazione valida dopo validazione")
            }
            
            // ==============================
            // PHASE 4: LOAD (Create BankImport)
            // ==============================
            log("📦 FASE 4: LOAD")
            
            let bankImport = createBankImport(
                from: validationResult!.validTransactions,
                fileURL: fileURL
            )
            
            log("   ✅ BankImport creato con \(bankImport.transactionCount) transazioni")
            log(String(format: "   💰 Totale entrate: €%.2f", bankImport.totalIncome))
            log(String(format: "   💸 Totale uscite: €%.2f", bankImport.totalExpenses))
            log(String(format: "   📊 Saldo netto: €%.2f", bankImport.netBalance))
            
            // ==============================
            // SUCCESS
            // ==============================
            let processingTime = Date().timeIntervalSince(startTime)
            
            let result = ETLPipelineResult(
                bankImport: bankImport,
                isSuccess: true,
                failedPhase: nil,
                error: nil,
                extractedRowCount: extractedRows.count,
                transformedTransactionCount: transformedTransactions.count,
                validTransactionCount: validationResult!.validCount,
                rejectedTransactionCount: extractedRows.count - validationResult!.validCount,
                warnings: warnings + validationResult!.warnings.map { $0.message },
                validationErrors: validationResult!.errors,
                processingTime: processingTime
            )
            
            log("✅ ETL completato con successo")
            log(String(format: "⏱️  Tempo totale: %.2f secondi", processingTime))
            
            return result
            
        } catch let error as BankImportError {
            // Determina fase fallita
            let failedPhase: ETLPhase
            if extractedRows.isEmpty {
                failedPhase = .extract
            } else if transformedTransactions.isEmpty {
                failedPhase = .transform
            } else if validationResult == nil || validationResult!.validTransactions.isEmpty {
                failedPhase = .validate
            } else {
                failedPhase = .load
            }
            
            log("❌ ETL fallito in fase \(failedPhase.rawValue)")
            log("   Errore: \(error.localizedDescription)")
            
            let processingTime = Date().timeIntervalSince(startTime)
            
            return ETLPipelineResult(
                bankImport: nil,
                isSuccess: false,
                failedPhase: failedPhase,
                error: error,
                extractedRowCount: extractedRows.count,
                transformedTransactionCount: transformedTransactions.count,
                validTransactionCount: validationResult?.validCount ?? 0,
                rejectedTransactionCount: extractedRows.count - (validationResult?.validCount ?? 0),
                warnings: warnings,
                validationErrors: validationResult?.errors ?? [],
                processingTime: processingTime
            )
        }
    }
    
    // MARK: - Private Methods
    
    private func createBankImport(
        from transactions: [BankTransaction],
        fileURL: URL
    ) -> BankImport {
        // Determina periodo dalle transazioni
        let dates = transactions.map { $0.date }
        let periodStart = dates.min()
        let periodEnd = dates.max()
        
        return BankImport(
            transactions: transactions,
            bankName: transformer.bankName,
            periodStart: periodStart,
            periodEnd: periodEnd,
            sourceFileName: fileURL.lastPathComponent,
            sourceFormat: fileURL.pathExtension.uppercased()
        )
    }
    
    private func log(_ message: String) {
        if configuration.verboseLogging {
            print(message)
        }
    }
}

// MARK: - Convenience Initializers

extension BankETLPipeline {
    /// Crea pipeline per Intesa Sanpaolo
    static func intesaSanpaolo(configuration: ETLPipelineConfiguration = .default) -> BankETLPipeline {
        let extractor = XLSXBankExtractor()
        let transformer = DefaultBankTransformer(bankName: "Intesa Sanpaolo")
        let validator = DefaultBankValidator(rules: nil)
        
        return BankETLPipeline(
            extractor: extractor,
            transformer: transformer,
            validator: validator,
            configuration: configuration
        )
    }
    
    /// Crea pipeline generico con nome banca custom
    static func generic(
        bankName: String,
        columnMapping: BankColumnMapping = .default,
        configuration: ETLPipelineConfiguration = .default
    ) -> BankETLPipeline {
        let extractor = XLSXBankExtractor()
        let transformer = DefaultBankTransformer(bankName: bankName)
        let validator = DefaultBankValidator(rules: nil)
        
        return BankETLPipeline(
            extractor: extractor,
            transformer: transformer,
            validator: validator,
            configuration: configuration,
            columnMapping: columnMapping
        )
    }
}

// MARK: - String Extension

fileprivate extension String {
    /// Ripete il carattere n volte
    static func * (left: String, right: Int) -> String {
        return String(repeating: left, count: right)
    }
}

// MARK: - Testing Helpers

#if DEBUG
extension BankETLPipeline {
    /// Pipeline per testing
    static var mock: BankETLPipeline {
        BankETLPipeline.generic(
            bankName: "Test Bank",
            configuration: .lenient
        )
    }
}

extension ETLPipelineResult {
    /// Risultato mock per testing
    static var mockSuccess: ETLPipelineResult {
        ETLPipelineResult(
            bankImport: .sample,
            isSuccess: true,
            failedPhase: nil,
            error: nil,
            extractedRowCount: 10,
            transformedTransactionCount: 10,
            validTransactionCount: 9,
            rejectedTransactionCount: 1,
            warnings: ["Mock warning"],
            validationErrors: [],
            processingTime: 1.23
        )
    }
    
    static var mockFailure: ETLPipelineResult {
        ETLPipelineResult(
            bankImport: nil,
            isSuccess: false,
            failedPhase: .transform,
            error: BankImportError.parsingFailed(details: "Mock error"),
            extractedRowCount: 10,
            transformedTransactionCount: 2,
            validTransactionCount: 0,
            rejectedTransactionCount: 10,
            warnings: [],
            validationErrors: [],
            processingTime: 0.5
        )
    }
}
#endif
