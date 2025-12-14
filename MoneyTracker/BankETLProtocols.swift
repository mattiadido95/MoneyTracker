//
//  BankETLProtocols.swift
//  MoneyTracker
//
//  Created by Assistant on 14/12/25.
//

/*
 PROTOCOLS - Bank ETL System
 
 Definisce le interfacce per il processo ETL (Extract, Transform, Load)
 degli estratti conto bancari.
 
 DESIGN PRINCIPLES:
 • Protocol-Oriented Design: Composizione > Ereditarietà
 • Single Responsibility: Ogni protocol ha un solo scopo
 • Dependency Inversion: Dipendenze da astrazioni, non implementazioni
 • Open/Closed: Aperto a estensioni (nuove banche), chiuso a modifiche
 
 ARCHITETTURA ETL:
 1. EXTRACT: Lettura dati grezzi da file (XLSX, CSV, PDF)
 2. TRANSFORM: Conversione in modello normalizzato (BankTransaction)
 3. VALIDATE: Verifica correttezza e completezza dati
 
 ESTENDIBILITÀ:
 - Aggiungi nuove banche implementando i protocol
 - Supporta nuovi formati implementando BankExtractor
 - Personalizza validazione per banca con BankValidator custom
*/

import Foundation

// MARK: - BankExtractor

/// Responsabilità: Estrarre dati grezzi da un file
///
/// Legge il file e restituisce una rappresentazione intermedia
/// dei dati (array di dizionari, righe CSV, oggetti JSON, ecc.)
/// NON conosce la struttura specifica della banca.
protocol BankExtractor {
    /// Formati file supportati da questo extractor
    var supportedFormats: [String] { get }
    
    /// Estrae dati grezzi dal file
    /// - Parameter fileURL: URL del file da leggere
    /// - Returns: Array di righe come dizionari [colonna: valore]
    /// - Throws: Errori di I/O o formato non valido
    func extract(from fileURL: URL) async throws -> [[String: Any]]
}

// MARK: - BankTransformer

/// Responsabilità: Trasformare dati grezzi in modello normalizzato
///
/// Converte la rappresentazione intermedia (estratta da BankExtractor)
/// in un array di BankTransaction secondo le regole specifiche della banca.
/// Conosce la struttura dei dati della banca (nomi colonne, formati, ecc.)
protocol BankTransformer {
    /// Nome della banca gestita
    var bankName: String { get }
    
    /// Identificatori univoci che permettono di riconoscere questa banca
    /// (es: header specifici, pattern nel nome file, marker nel contenuto)
    var bankIdentifiers: [String] { get }
    
    /// Trasforma dati grezzi in transazioni normalizzate
    /// - Parameter rawData: Dati estratti da BankExtractor
    /// - Returns: Array di BankTransaction normalizzate
    /// - Throws: Errori di parsing o dati mancanti
    func transform(_ rawData: [[String: Any]]) async throws -> [BankTransaction]
    
    /// Riconosce se i dati appartengono a questa banca
    /// - Parameter rawData: Dati da verificare
    /// - Returns: true se il formato è riconosciuto
    func canHandle(_ rawData: [[String: Any]]) -> Bool
}

// MARK: - BankValidator

/// Responsabilità: Validare correttezza e completezza dei dati
///
/// Verifica che le transazioni siano valide secondo regole di business
/// (date coerenti, importi positivi, campi obbligatori presenti, ecc.)
/// Può essere generico o specializzato per banca.
protocol BankValidator {
    /// Valida un array di transazioni
    /// - Parameter transactions: Transazioni da validare
    /// - Returns: Risultato validazione con errori specifici
    func validate(_ transactions: [BankTransaction]) -> ValidationResult
    
    /// Valida una singola transazione
    /// - Parameter transaction: Transazione da validare
    /// - Returns: true se valida, false altrimenti
    func isValid(_ transaction: BankTransaction) -> Bool
}

// MARK: - Composite Protocol

/// Protocol composito che combina tutte le fasi ETL
///
/// Una classe che implementa BankStatementParser può gestire
/// l'intero processo ETL per una specifica banca.
/// Utile per implementazioni "all-in-one".
protocol BankStatementParser: BankExtractor, BankTransformer, BankValidator {
    /// Processo ETL completo: Extract → Transform → Validate
    /// - Parameter fileURL: URL del file da importare
    /// - Returns: BankImport completo e validato
    /// - Throws: Errori in qualsiasi fase del processo
    func parse(fileURL: URL) async throws -> BankImport
}

// MARK: - Validation Result

/// Risultato di una validazione con dettagli sugli errori
struct ValidationResult {
    /// Validazione completamente superata
    let isValid: Bool
    
    /// Errori riscontrati (vuoto se isValid == true)
    let errors: [ValidationError]
    
    /// Warnings non bloccanti
    let warnings: [ValidationWarning]
    
    /// Numero transazioni valide
    let validCount: Int
    
    /// Numero transazioni non valide
    let invalidCount: Int
    
    /// Risultato valido senza errori
    static var success: ValidationResult {
        ValidationResult(
            isValid: true,
            errors: [],
            warnings: [],
            validCount: 0,
            invalidCount: 0
        )
    }
    
    /// Crea risultato da lista errori
    static func failure(errors: [ValidationError], validCount: Int = 0, invalidCount: Int = 0) -> ValidationResult {
        ValidationResult(
            isValid: false,
            errors: errors,
            warnings: [],
            validCount: validCount,
            invalidCount: invalidCount
        )
    }
}

// MARK: - Validation Error

/// Errore di validazione specifico
struct ValidationError: Identifiable {
    let id = UUID()
    
    /// Indice transazione con errore (se applicabile)
    var transactionIndex: Int?
    
    /// ID transazione con errore (se disponibile)
    let transactionID: UUID?
    
    /// Tipo di errore
    let type: ErrorType
    
    /// Descrizione dell'errore
    let message: String
    
    /// Campo che ha causato l'errore
    let field: String?
    
    enum ErrorType {
        case missingRequiredField
        case invalidAmount
        case invalidDate
        case invalidFormat
        case businessRuleViolation
        case other
    }
}

// MARK: - Validation Warning

/// Warning non bloccante
struct ValidationWarning: Identifiable {
    let id = UUID()
    
    /// Indice transazione
    var transactionIndex: Int?
    
    /// Messaggio warning
    let message: String
    
    /// Tipo di warning
    let type: WarningType
    
    enum WarningType {
        case missingOptionalField
        case unusualAmount
        case suspiciousPattern
        case dataQualityIssue
        case other
    }
}

// MARK: - Default Implementations

extension BankValidator {
    /// Implementazione base di isValid (delega a validate)
    func isValid(_ transaction: BankTransaction) -> Bool {
        let result = validate([transaction])
        return result.isValid
    }
}

extension BankStatementParser {
    /// Implementazione default del processo ETL completo
    func parse(fileURL: URL) async throws -> BankImport {
        // 1. EXTRACT
        let rawData = try await extract(from: fileURL)
        
        // 2. TRANSFORM
        let transactions = try await transform(rawData)
        
        // 3. VALIDATE
        let validationResult = validate(transactions)
        
        guard validationResult.isValid else {
            throw BankImportError.parsingFailed(
                details: "Validazione fallita: \(validationResult.errors.count) errori"
            )
        }
        
        // 4. CREATE IMPORT
        let bankImport = BankImport(
            transactions: transactions,
            bankName: bankName,
            sourceFileName: fileURL.lastPathComponent,
            sourceFormat: fileURL.pathExtension.uppercased()
        )
        
        return bankImport
    }
}

// MARK: - Parser Registry Protocol

/// Protocol per registrare e recuperare parser specifici per banca
protocol BankParserRegistry {
    /// Registra un parser per una banca
    func register(parser: BankStatementParser)
    
    /// Trova il parser appropriato per i dati forniti
    func findParser(for rawData: [[String: Any]]) -> BankStatementParser?
    
    /// Trova il parser per nome banca
    func findParser(byBankName name: String) -> BankStatementParser?
    
    /// Tutti i parser registrati
    var allParsers: [BankStatementParser] { get }
}
