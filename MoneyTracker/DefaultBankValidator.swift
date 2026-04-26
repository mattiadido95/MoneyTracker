//
//  DefaultBankValidator.swift
//  MoneyTracker
//
//  Created by Assistant on 14/12/25.
//

/*
 VALIDATOR - Bank Transaction Validator
 
 Responsabilità: Validare correttezza e completezza delle BankTransaction
 
 DESIGN:
 • Regole di business configurabili
 • Validazione batch con report dettagliato
 • Separazione transazioni valide/invalide
 • Error reporting preciso per debugging
 • Warning per problemi non bloccanti
 
 UTILIZZO:
 let validator = DefaultBankValidator()
 let result = validator.validate(transactions)
 
 if result.isValid {
     print("Tutte le \(result.validTransactions.count) transazioni sono valide")
 } else {
     print("Errori trovati: \(result.errors.count)")
 }
*/

import Foundation

// MARK: - BankValidationResult

/// Risultato completo di una validazione batch
struct BankValidationResult {
    
    // MARK: - Properties
    
    /// Validazione completamente superata (zero errori)
    let isValid: Bool
    
    /// Transazioni valide
    let validTransactions: [BankTransaction]
    
    /// Transazioni invalide
    let invalidTransactions: [BankTransaction]
    
    /// Errori riscontrati (uno per transazione invalida)
    let errors: [ValidationError]
    
    /// Warning non bloccanti
    let warnings: [ValidationWarning]
    
    // MARK: - Computed Properties
    
    /// Numero transazioni valide
    var validCount: Int {
        validTransactions.count
    }
    
    /// Numero transazioni invalide
    var invalidCount: Int {
        invalidTransactions.count
    }
    
    /// Numero totale transazioni
    var totalCount: Int {
        validCount + invalidCount
    }
    
    /// Percentuale successo
    var successRate: Double {
        guard totalCount > 0 else { return 0 }
        return Double(validCount) / Double(totalCount) * 100.0
    }
    
    /// Summary testuale
    var summary: String {
        var lines: [String] = []
        
        lines.append("📊 Risultati Validazione")
        lines.append("━━━━━━━━━━━━━━━━━━━━━━")
        lines.append("Totale: \(totalCount) transazioni")
        lines.append("✅ Valide: \(validCount)")
        lines.append("❌ Invalide: \(invalidCount)")
        lines.append("⚠️  Warning: \(warnings.count)")
        lines.append(String(format: "📈 Tasso successo: %.1f%%", successRate))
        
        if !errors.isEmpty {
            lines.append("\nErrori:")
            for (index, error) in errors.prefix(5).enumerated() {
                lines.append("  \(index + 1). \(error.message)")
            }
            if errors.count > 5 {
                lines.append("  ... e altri \(errors.count - 5) errori")
            }
        }
        
        return lines.joined(separator: "\n")
    }
    
    // MARK: - Factory Methods
    
    /// Risultato con tutte transazioni valide
    static func success(transactions: [BankTransaction], warnings: [ValidationWarning] = []) -> BankValidationResult {
        BankValidationResult(
            isValid: true,
            validTransactions: transactions,
            invalidTransactions: [],
            errors: [],
            warnings: warnings
        )
    }
    
    /// Risultato con errori
    static func failure(
        validTransactions: [BankTransaction],
        invalidTransactions: [BankTransaction],
        errors: [ValidationError],
        warnings: [ValidationWarning] = []
    ) -> BankValidationResult {
        BankValidationResult(
            isValid: false,
            validTransactions: validTransactions,
            invalidTransactions: invalidTransactions,
            errors: errors,
            warnings: warnings
        )
    }
}

// MARK: - Validation Rule

/// Protocol per regola di validazione singola
protocol ValidationRule {
    /// Nome della regola
    var name: String { get }
    
    /// Valida una transazione
    /// - Parameter transaction: Transazione da validare
    /// - Returns: nil se valida, ValidationError se invalida
    func validate(_ transaction: BankTransaction) -> ValidationError?
    
    /// Valida e produce warning (opzionale)
    /// - Parameter transaction: Transazione da validare
    /// - Returns: nil o ValidationWarning
    func warning(_ transaction: BankTransaction) -> ValidationWarning?
}

// Default implementation per warning
extension ValidationRule {
    func warning(_ transaction: BankTransaction) -> ValidationWarning? {
        return nil
    }
}

// MARK: - Default Validation Rules

/// Regola: data deve essere valida e ragionevole
struct DateValidationRule: ValidationRule {
    let name = "Date Validation"
    
    /// Data minima accettabile (es: 10 anni fa)
    let minimumDate: Date
    
    /// Data massima accettabile (es: domani)
    let maximumDate: Date
    
    init(
        minimumDate: Date = Calendar.current.date(byAdding: .year, value: -10, to: Date())!,
        maximumDate: Date = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
    ) {
        self.minimumDate = minimumDate
        self.maximumDate = maximumDate
    }
    
    func validate(_ transaction: BankTransaction) -> ValidationError? {
        if transaction.date < minimumDate {
            return ValidationError(
                transactionIndex: nil,
                transactionID: transaction.id,
                type: .invalidDate,
                message: "Data troppo vecchia: \(formatDate(transaction.date))",
                field: "date"
            )
        }
        
        if transaction.date > maximumDate {
            return ValidationError(
                transactionIndex: nil,
                transactionID: transaction.id,
                type: .invalidDate,
                message: "Data futura non valida: \(formatDate(transaction.date))",
                field: "date"
            )
        }
        
        return nil
    }
    
    func warning(_ transaction: BankTransaction) -> ValidationWarning? {
        // Warning se data è molto recente (oggi)
        let today = Calendar.current.startOfDay(for: Date())
        let transactionDay = Calendar.current.startOfDay(for: transaction.date)
        
        if transactionDay == today {
            return ValidationWarning(
                transactionIndex: nil,
                message: "Transazione molto recente (oggi)",
                type: .dataQualityIssue
            )
        }
        
        return nil
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "it_IT")
        return formatter.string(from: date)
    }
}

/// Regola: importo deve essere > 0
struct AmountValidationRule: ValidationRule {
    let name = "Amount Validation"
    
    /// Importo minimo accettabile
    let minimumAmount: Double
    
    /// Importo massimo (per rilevare anomalie)
    let maximumAmount: Double?
    
    /// Soglia per warning su importi alti
    let highAmountThreshold: Double?
    
    init(
        minimumAmount: Double = 0.01,
        maximumAmount: Double? = nil,
        highAmountThreshold: Double? = 10000.0
    ) {
        self.minimumAmount = minimumAmount
        self.maximumAmount = maximumAmount
        self.highAmountThreshold = highAmountThreshold
    }
    
    func validate(_ transaction: BankTransaction) -> ValidationError? {
        if transaction.amount <= 0 {
            return ValidationError(
                transactionIndex: nil,
                transactionID: transaction.id,
                type: .invalidAmount,
                message: "Importo deve essere maggiore di zero (trovato: \(transaction.amount))",
                field: "amount"
            )
        }
        
        if transaction.amount < minimumAmount {
            return ValidationError(
                transactionIndex: nil,
                transactionID: transaction.id,
                type: .invalidAmount,
                message: "Importo troppo piccolo: €\(String(format: "%.2f", transaction.amount))",
                field: "amount"
            )
        }
        
        if let maxAmount = maximumAmount, transaction.amount > maxAmount {
            return ValidationError(
                transactionIndex: nil,
                transactionID: transaction.id,
                type: .invalidAmount,
                message: "Importo troppo alto: €\(String(format: "%.2f", transaction.amount))",
                field: "amount"
            )
        }
        
        return nil
    }
    
    func warning(_ transaction: BankTransaction) -> ValidationWarning? {
        if let threshold = highAmountThreshold, transaction.amount > threshold {
            return ValidationWarning(
                transactionIndex: nil,
                message: "Importo insolitamente alto: €\(String(format: "%.2f", transaction.amount))",
                type: .unusualAmount
            )
        }
        return nil
    }
}

/// Regola: descrizione non vuota
struct DescriptionValidationRule: ValidationRule {
    let name = "Description Validation"
    
    /// Lunghezza minima descrizione
    let minimumLength: Int
    
    init(minimumLength: Int = 1) {
        self.minimumLength = minimumLength
    }
    
    func validate(_ transaction: BankTransaction) -> ValidationError? {
        let trimmed = transaction.description.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmed.isEmpty {
            return ValidationError(
                transactionIndex: nil,
                transactionID: transaction.id,
                type: .missingRequiredField,
                message: "Descrizione obbligatoria",
                field: "description"
            )
        }
        
        if trimmed.count < minimumLength {
            return ValidationError(
                transactionIndex: nil,
                transactionID: transaction.id,
                type: .invalidFormat,
                message: "Descrizione troppo corta (minimo \(minimumLength) caratteri)",
                field: "description"
            )
        }
        
        return nil
    }
    
    func warning(_ transaction: BankTransaction) -> ValidationWarning? {
        // Warning se descrizione è molto breve (ma > minimum)
        if transaction.description.count < 5 && transaction.description.count >= minimumLength {
            return ValidationWarning(
                transactionIndex: nil,
                message: "Descrizione molto breve: '\(transaction.description)'",
                type: .dataQualityIssue
            )
        }
        return nil
    }
}

/// Regola: campi opzionali ma raccomandati
struct OptionalFieldsRule: ValidationRule {
    let name = "Optional Fields Check"
    
    func validate(_ transaction: BankTransaction) -> ValidationError? {
        // Nessun errore bloccante
        return nil
    }
    
    func warning(_ transaction: BankTransaction) -> ValidationWarning? {
        var missingFields: [String] = []
        
        if transaction.category == nil {
            missingFields.append("categoria")
        }
        
        if transaction.counterparty == nil {
            missingFields.append("beneficiario")
        }
        
        if !missingFields.isEmpty {
            return ValidationWarning(
                transactionIndex: nil,
                message: "Campi opzionali mancanti: \(missingFields.joined(separator: ", "))",
                type: .missingOptionalField
            )
        }
        
        return nil
    }
}

// MARK: - DefaultBankValidator

/// Validatore standard per BankTransaction
class DefaultBankValidator: BankValidator {
    
    // MARK: - Properties
    
    /// Regole di validazione attive
    private(set) var rules: [ValidationRule]
    
    /// Include warning nel risultato
    var includeWarnings: Bool = true
    
    // MARK: - Initialization
    
    init(rules: [ValidationRule]? = nil) {
        if let customRules = rules {
            self.rules = customRules
        } else {
            // Regole di default
            self.rules = [
                DateValidationRule(),
                AmountValidationRule(),
                DescriptionValidationRule()
            ]
        }
    }
    
    /// Inizializza con regole di default + opzionali
    convenience init(includeOptionalFieldsCheck: Bool = false) {
        var rules: [ValidationRule] = [
            DateValidationRule(),
            AmountValidationRule(),
            DescriptionValidationRule()
        ]
        
        if includeOptionalFieldsCheck {
            rules.append(OptionalFieldsRule())
        }
        
        self.init(rules: rules)
    }
    
    // MARK: - BankValidator Conformance
    
    func validate(_ transactions: [BankTransaction]) -> ValidationResult {
        var validTransactions: [BankTransaction] = []
        var invalidTransactions: [BankTransaction] = []
        var allErrors: [ValidationError] = []
        var allWarnings: [ValidationWarning] = []
        
        for (index, transaction) in transactions.enumerated() {
            var hasError = false
            
            // Applica tutte le regole
            for rule in rules {
                // Check errori
                if let error = rule.validate(transaction) {
                    var errorWithIndex = error
                    errorWithIndex.transactionIndex = index
                    allErrors.append(errorWithIndex)
                    hasError = true
                }
                
                // Check warning
                if includeWarnings, let warning = rule.warning(transaction) {
                    var warningWithIndex = warning
                    warningWithIndex.transactionIndex = index
                    allWarnings.append(warningWithIndex)
                }
            }
            
            // Classifica transazione
            if hasError {
                invalidTransactions.append(transaction)
            } else {
                validTransactions.append(transaction)
            }
        }
        
        // Costruisci risultato
        let bankValidationResult = BankValidationResult(
            isValid: allErrors.isEmpty,
            validTransactions: validTransactions,
            invalidTransactions: invalidTransactions,
            errors: allErrors,
            warnings: allWarnings
        )
        
        // Converti a ValidationResult (protocol requirement)
        return ValidationResult(
            isValid: bankValidationResult.isValid,
            errors: allErrors,
            warnings: allWarnings,
            validCount: validTransactions.count,
            invalidCount: invalidTransactions.count
        )
    }
    
    func isValid(_ transaction: BankTransaction) -> Bool {
        for rule in rules {
            if rule.validate(transaction) != nil {
                return false
            }
        }
        return true
    }
    
    // MARK: - Enhanced Validation
    
    /// Validazione completa con risultato dettagliato
    /// - Parameter transactions: Array di transazioni da validare
    /// - Returns: BankValidationResult con transazioni separate
    func validateDetailed(_ transactions: [BankTransaction]) -> BankValidationResult {
        var validTransactions: [BankTransaction] = []
        var invalidTransactions: [BankTransaction] = []
        var allErrors: [ValidationError] = []
        var allWarnings: [ValidationWarning] = []
        
        for (index, transaction) in transactions.enumerated() {
            var hasError = false
            
            // Applica tutte le regole
            for rule in rules {
                // Check errori
                if var error = rule.validate(transaction) {
                    error.transactionIndex = index
                    allErrors.append(error)
                    hasError = true
                }
                
                // Check warning
                if includeWarnings, var warning = rule.warning(transaction) {
                    warning.transactionIndex = index
                    allWarnings.append(warning)
                }
            }
            
            // Classifica transazione
            if hasError {
                invalidTransactions.append(transaction)
            } else {
                validTransactions.append(transaction)
            }
        }
        
        return BankValidationResult(
            isValid: allErrors.isEmpty,
            validTransactions: validTransactions,
            invalidTransactions: invalidTransactions,
            errors: allErrors,
            warnings: allWarnings
        )
    }
    
    // MARK: - Rule Management
    
    /// Aggiunge una regola custom
    func addRule(_ rule: ValidationRule) {
        rules.append(rule)
    }
    
    /// Rimuove tutte le regole
    func clearRules() {
        rules.removeAll()
    }
    
    /// Reset a regole di default
    func resetToDefaultRules() {
        rules = [
            DateValidationRule(),
            AmountValidationRule(),
            DescriptionValidationRule()
        ]
    }
}

// MARK: - Convenience Extensions

extension ValidationError {
    /// Crea errore da transazione e tipo
    static func from(
        transaction: BankTransaction,
        type: ErrorType,
        message: String,
        field: String?
    ) -> ValidationError {
        ValidationError(
            transactionIndex: nil,
            transactionID: transaction.id,
            type: type,
            message: message,
            field: field
        )
    }
}

extension ValidationWarning {
    /// Crea warning da transazione
    static func from(
        transaction: BankTransaction,
        type: WarningType,
        message: String
    ) -> ValidationWarning {
        ValidationWarning(
            transactionIndex: nil,
            message: message,
            type: type
        )
    }
}

// MARK: - Testing Helpers

#if DEBUG
extension DefaultBankValidator {
    /// Validator per testing (solo regole base)
    static var mock: DefaultBankValidator {
        DefaultBankValidator(rules: nil)
    }
    
    /// Validator strict per testing (tutte le regole)
    static var strict: DefaultBankValidator {
        let validator = DefaultBankValidator(includeOptionalFieldsCheck: true)
        validator.includeWarnings = true
        return validator
    }
}
#endif
