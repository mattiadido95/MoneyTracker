//
//  BankImport.swift
//  MoneyTracker
//
//  Created by Assistant on 14/12/25.
//

/*
 MODELLO DATI - BankImport (Import Estratto Conto)
 
 Rappresenta un intero import di estratto conto bancario con metadati e transazioni.
 
 DESIGN PRINCIPLES:
 • Codable: Serializzazione JSON completa con ISO8601
 • Identifiable: UUID per tracciamento import
 • Immutabile: Value semantics per thread-safety
 • Rich metadata: Traccia fonte, periodo, statistiche
 
 FUNZIONALITÀ:
 - Raggruppa tutte le transazioni di un singolo import
 - Metadati completi su fonte e periodo
 - Statistiche calcolate automaticamente
 - Timestamp per audit trail
 - Supporto versionamento formato
 
 UTILIZZO ETL:
 - ETLCoordinator produce BankImport dopo parsing
 - Può essere serializzato per cache/backup
 - Rappresenta l'output completo del processo Extract+Transform
 - Input per fase Load (conversione a CategoriaSpesa)
*/

import Foundation

// MARK: - BankImport

struct BankImport: Codable, Identifiable {
    // MARK: - Core Properties
    
    /// Identificatore univoco dell'import
    let id: UUID
    
    /// Lista di transazioni importate
    let transactions: [BankTransaction]
    
    // MARK: - Metadata
    
    /// Nome della banca
    let bankName: String
    
    /// Tipo/Nome account (es: "Conto Corrente", "Carta di Credito")
    let accountType: String?
    
    /// Numero account mascherato (es: "****1234")
    let maskedAccountNumber: String?
    
    /// Data di inizio periodo dell'estratto conto
    let periodStart: Date?
    
    /// Data di fine periodo dell'estratto conto
    let periodEnd: Date?
    
    /// Timestamp dell'import
    let importedAt: Date
    
    /// Nome del file originale
    let sourceFileName: String
    
    /// Formato del file sorgente (es: "XLSX", "CSV", "PDF")
    let sourceFormat: String
    
    /// Versione del parser utilizzato
    let parserVersion: String
    
    // MARK: - Statistics (Computed)
    
    /// Numero totale di transazioni
    var transactionCount: Int {
        transactions.count
    }
    
    /// Numero di uscite
    var expenseCount: Int {
        transactions.filter { $0.type == .expense }.count
    }
    
    /// Numero di entrate
    var incomeCount: Int {
        transactions.filter { $0.type == .income }.count
    }
    
    /// Totale uscite
    var totalExpenses: Double {
        transactions
            .filter { $0.type == .expense }
            .reduce(0) { $0 + $1.amount }
    }
    
    /// Totale entrate
    var totalIncome: Double {
        transactions
            .filter { $0.type == .income }
            .reduce(0) { $0 + $1.amount }
    }
    
    /// Bilancio netto (entrate - uscite)
    var netBalance: Double {
        totalIncome - totalExpenses
    }
    
    /// Range di date delle transazioni
    var dateRange: ClosedRange<Date>? {
        guard let minDate = transactions.map({ $0.date }).min(),
              let maxDate = transactions.map({ $0.date }).max() else {
            return nil
        }
        return minDate...maxDate
    }
    
    // MARK: - Initialization
    
    init(
        id: UUID = UUID(),
        transactions: [BankTransaction],
        bankName: String,
        accountType: String? = nil,
        maskedAccountNumber: String? = nil,
        periodStart: Date? = nil,
        periodEnd: Date? = nil,
        importedAt: Date = Date(),
        sourceFileName: String,
        sourceFormat: String,
        parserVersion: String = "1.0"
    ) {
        self.id = id
        self.transactions = transactions
        self.bankName = bankName
        self.accountType = accountType
        self.maskedAccountNumber = maskedAccountNumber
        self.periodStart = periodStart
        self.periodEnd = periodEnd
        self.importedAt = importedAt
        self.sourceFileName = sourceFileName
        self.sourceFormat = sourceFormat
        self.parserVersion = parserVersion
    }
    
    // MARK: - Methods
    
    /// Filtra transazioni per tipo
    func transactions(ofType type: TransactionType) -> [BankTransaction] {
        transactions.filter { $0.type == type }
    }
    
    /// Filtra transazioni per periodo
    func transactions(from startDate: Date, to endDate: Date) -> [BankTransaction] {
        transactions.filter { $0.date >= startDate && $0.date <= endDate }
    }
    
    /// Filtra transazioni per categoria
    func transactions(withCategory category: String) -> [BankTransaction] {
        transactions.filter { $0.category?.lowercased() == category.lowercased() }
    }
    
    /// Raggruppa transazioni per mese
    func transactionsByMonth() -> [String: [BankTransaction]] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        
        return Dictionary(grouping: transactions) { transaction in
            formatter.string(from: transaction.date)
        }
    }
    
    /// Riassunto testuale dell'import
    var summary: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.locale = Locale(identifier: "it_IT")
        
        var lines: [String] = []
        lines.append("Import da \(bankName)")
        lines.append("File: \(sourceFileName)")
        lines.append("Data import: \(dateFormatter.string(from: importedAt))")
        lines.append("Transazioni: \(transactionCount) (\(incomeCount) entrate, \(expenseCount) uscite)")
        
        if let start = periodStart, let end = periodEnd {
            lines.append("Periodo: \(dateFormatter.string(from: start)) - \(dateFormatter.string(from: end))")
        }
        
        lines.append(String(format: "Totale entrate: €%.2f", totalIncome))
        lines.append(String(format: "Totale uscite: €%.2f", totalExpenses))
        lines.append(String(format: "Saldo netto: €%.2f", netBalance))
        
        return lines.joined(separator: "\n")
    }
}

// MARK: - Codable Configuration

extension BankImport {
    /// Custom encoder per date ISO8601
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        try container.encode(id, forKey: .id)
        try container.encode(transactions, forKey: .transactions)
        try container.encode(bankName, forKey: .bankName)
        try container.encodeIfPresent(accountType, forKey: .accountType)
        try container.encodeIfPresent(maskedAccountNumber, forKey: .maskedAccountNumber)
        try container.encode(sourceFileName, forKey: .sourceFileName)
        try container.encode(sourceFormat, forKey: .sourceFormat)
        try container.encode(parserVersion, forKey: .parserVersion)
        
        // Encode dates
        try container.encode(dateFormatter.string(from: importedAt), forKey: .importedAt)
        
        if let periodStart = periodStart {
            try container.encode(dateFormatter.string(from: periodStart), forKey: .periodStart)
        }
        
        if let periodEnd = periodEnd {
            try container.encode(dateFormatter.string(from: periodEnd), forKey: .periodEnd)
        }
    }
    
    /// Custom decoder per date ISO8601
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        id = try container.decode(UUID.self, forKey: .id)
        transactions = try container.decode([BankTransaction].self, forKey: .transactions)
        bankName = try container.decode(String.self, forKey: .bankName)
        accountType = try container.decodeIfPresent(String.self, forKey: .accountType)
        maskedAccountNumber = try container.decodeIfPresent(String.self, forKey: .maskedAccountNumber)
        sourceFileName = try container.decode(String.self, forKey: .sourceFileName)
        sourceFormat = try container.decode(String.self, forKey: .sourceFormat)
        parserVersion = try container.decode(String.self, forKey: .parserVersion)
        
        // Decode importedAt
        let importedAtString = try container.decode(String.self, forKey: .importedAt)
        if let date = dateFormatter.date(from: importedAtString) {
            importedAt = date
        } else {
            dateFormatter.formatOptions = [.withInternetDateTime]
            if let date = dateFormatter.date(from: importedAtString) {
                importedAt = date
            } else {
                throw DecodingError.dataCorruptedError(
                    forKey: .importedAt,
                    in: container,
                    debugDescription: "Date string non valida: \(importedAtString)"
                )
            }
        }
        
        // Decode optional dates
        if let periodStartString = try container.decodeIfPresent(String.self, forKey: .periodStart) {
            dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            periodStart = dateFormatter.date(from: periodStartString) ?? {
                dateFormatter.formatOptions = [.withInternetDateTime]
                return dateFormatter.date(from: periodStartString)
            }()
        } else {
            periodStart = nil
        }
        
        if let periodEndString = try container.decodeIfPresent(String.self, forKey: .periodEnd) {
            dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            periodEnd = dateFormatter.date(from: periodEndString) ?? {
                dateFormatter.formatOptions = [.withInternetDateTime]
                return dateFormatter.date(from: periodEndString)
            }()
        } else {
            periodEnd = nil
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case id, transactions, bankName, accountType, maskedAccountNumber
        case periodStart, periodEnd, importedAt
        case sourceFileName, sourceFormat, parserVersion
    }
}

// MARK: - Sample Data

extension BankImport {
    /// Import di esempio per preview/testing
    static var sample: BankImport {
        BankImport(
            transactions: BankTransaction.samples,
            bankName: "Intesa Sanpaolo",
            accountType: "Conto Corrente",
            maskedAccountNumber: "****1234",
            periodStart: Calendar.current.date(byAdding: .month, value: -1, to: Date()),
            periodEnd: Date(),
            sourceFileName: "estratto_conto_ottobre_2024.xlsx",
            sourceFormat: "XLSX",
            parserVersion: "1.0"
        )
    }
    
    /// Import vuoto per testing
    static var empty: BankImport {
        BankImport(
            transactions: [],
            bankName: "Test Bank",
            sourceFileName: "empty.xlsx",
            sourceFormat: "XLSX"
        )
    }
}

// MARK: - Import Result

/// Risultato di un'operazione di import
enum BankImportResult {
    /// Import completato con successo
    case success(BankImport)
    
    /// Import fallito con errore
    case failure(BankImportError)
    
    /// Import parziale (alcune transazioni fallite)
    case partial(BankImport, errors: [BankImportError])
}

// MARK: - Import Errors

enum BankImportError: LocalizedError {
    case fileNotFound
    case invalidFileFormat
    case unsupportedBank
    case parsingFailed(details: String)
    case emptyFile
    case invalidData(row: Int, reason: String)
    case missingRequiredField(field: String)
    case dateParsingFailed(value: String)
    case amountParsingFailed(value: String)
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "File non trovato"
        case .invalidFileFormat:
            return "Formato file non valido"
        case .unsupportedBank:
            return "Banca non supportata"
        case .parsingFailed(let details):
            return "Parsing fallito: \(details)"
        case .emptyFile:
            return "Il file è vuoto"
        case .invalidData(let row, let reason):
            return "Dati non validi alla riga \(row): \(reason)"
        case .missingRequiredField(let field):
            return "Campo obbligatorio mancante: \(field)"
        case .dateParsingFailed(let value):
            return "Impossibile convertire la data: \(value)"
        case .amountParsingFailed(let value):
            return "Importo non valido: \(value)"
        }
    }
}
