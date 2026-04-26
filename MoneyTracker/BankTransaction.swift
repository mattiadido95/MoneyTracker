//
//  BankTransaction.swift
//  MoneyTracker
//
//  Created by Assistant on 14/12/25.
//

/*
 MODELLO DATI - BankTransaction (Transazione Bancaria Normalizzata)
 
 Rappresenta una singola transazione bancaria in formato normalizzato,
 indipendente dal formato della banca di origine.
 
 DESIGN PRINCIPLES:
 • Codable: Serializzazione JSON automatica con date ISO8601
 • Identifiable: UUID per identificazione univoca
 • Immutabile: Tutte le proprietà sono let (value semantics)
 • Type-safe: Enum per tipo transazione e valuta
 
 FUNZIONALITÀ:
 - Rappresentazione normalizzata di transazioni da qualsiasi banca
 - Supporto entrate/uscite con importi sempre positivi
 - Metadati completi (descrizione, categoria, note)
 - Valuta configurabile (default EUR)
 - Timestamp ISO8601 per interoperabilità
 
 UTILIZZO ETL:
 - I parser bancari producono array di BankTransaction
 - BankImport le raggruppa con metadati
 - TransactionMapper le converte in CategoriaSpesa
*/

import Foundation

// MARK: - BankTransaction

struct BankTransaction: Codable, Identifiable {
    // MARK: - Core Properties
    
    /// Identificatore univoco della transazione
    let id: UUID
    
    /// Data e ora della transazione
    let date: Date
    
    /// Importo della transazione (sempre positivo)
    let amount: Double
    
    /// Tipo di transazione (entrata o uscita)
    let type: TransactionType
    
    /// Valuta della transazione (default EUR)
    let currency: Currency
    
    // MARK: - Descriptive Properties
    
    /// Descrizione principale della transazione
    let description: String
    
    /// Categoria (opzionale, può essere inferita da AI)
    let category: String?
    
    /// Note aggiuntive o dettagli dalla banca
    let notes: String?
    
    /// Beneficiario/Ordinante (se disponibile)
    let counterparty: String?
    
    // MARK: - Metadata
    
    /// Identificatore originale dalla banca (se presente)
    let originalID: String?
    
    /// Nome della banca di origine
    let bankSource: String
    
    // MARK: - Initialization
    
    init(
        id: UUID = UUID(),
        date: Date,
        amount: Double,
        type: TransactionType,
        currency: Currency = .EUR,
        description: String,
        category: String? = nil,
        notes: String? = nil,
        counterparty: String? = nil,
        originalID: String? = nil,
        bankSource: String
    ) {
        self.id = id
        self.date = date
        self.amount = abs(amount) // Garantisce sempre positivo
        self.type = type
        self.currency = currency
        self.description = description
        self.category = category
        self.notes = notes
        self.counterparty = counterparty
        self.originalID = originalID
        self.bankSource = bankSource
    }
    
    // MARK: - Computed Properties
    
    /// Importo con segno (negativo per uscite, positivo per entrate)
    var signedAmount: Double {
        switch type {
        case .expense:
            return -amount
        case .income:
            return amount
        }
    }
    
    /// Formattazione completa dell'importo con valuta
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency.code
        formatter.locale = Locale(identifier: "it_IT")
        return formatter.string(from: NSNumber(value: signedAmount)) ?? "\(currency.symbol)\(signedAmount)"
    }
}

// MARK: - TransactionType

enum TransactionType: String, Codable {
    /// Uscita di denaro (spesa)
    case expense = "expense"
    
    /// Entrata di denaro (reddito)
    case income = "income"
    
    var localizedName: String {
        switch self {
        case .expense:
            return "Uscita"
        case .income:
            return "Entrata"
        }
    }
    
    var symbol: String {
        switch self {
        case .expense:
            return "↓"
        case .income:
            return "↑"
        }
    }
}

// MARK: - Currency

enum Currency: String, Codable {
    case EUR = "EUR"
    case USD = "USD"
    case GBP = "GBP"
    case CHF = "CHF"
    
    var symbol: String {
        switch self {
        case .EUR: return "€"
        case .USD: return "$"
        case .GBP: return "£"
        case .CHF: return "CHF"
        }
    }
    
    var code: String {
        return self.rawValue
    }
    
    var localizedName: String {
        switch self {
        case .EUR: return "Euro"
        case .USD: return "Dollaro USA"
        case .GBP: return "Sterlina"
        case .CHF: return "Franco Svizzero"
        }
    }
}

// MARK: - Codable Configuration

extension BankTransaction {
    /// Custom encoder per date ISO8601
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(amount, forKey: .amount)
        try container.encode(type, forKey: .type)
        try container.encode(currency, forKey: .currency)
        try container.encode(description, forKey: .description)
        try container.encodeIfPresent(category, forKey: .category)
        try container.encodeIfPresent(notes, forKey: .notes)
        try container.encodeIfPresent(counterparty, forKey: .counterparty)
        try container.encodeIfPresent(originalID, forKey: .originalID)
        try container.encode(bankSource, forKey: .bankSource)
        
        // Encode date in ISO8601 format
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let dateString = dateFormatter.string(from: date)
        try container.encode(dateString, forKey: .date)
    }
    
    /// Custom decoder per date ISO8601
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        amount = try container.decode(Double.self, forKey: .amount)
        type = try container.decode(TransactionType.self, forKey: .type)
        currency = try container.decode(Currency.self, forKey: .currency)
        description = try container.decode(String.self, forKey: .description)
        category = try container.decodeIfPresent(String.self, forKey: .category)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        counterparty = try container.decodeIfPresent(String.self, forKey: .counterparty)
        originalID = try container.decodeIfPresent(String.self, forKey: .originalID)
        bankSource = try container.decode(String.self, forKey: .bankSource)
        
        // Decode date from ISO8601 format
        let dateString = try container.decode(String.self, forKey: .date)
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let parsedDate = dateFormatter.date(from: dateString) {
            date = parsedDate
        } else {
            // Fallback: prova senza fractional seconds
            dateFormatter.formatOptions = [.withInternetDateTime]
            if let parsedDate = dateFormatter.date(from: dateString) {
                date = parsedDate
            } else {
                throw DecodingError.dataCorruptedError(
                    forKey: .date,
                    in: container,
                    debugDescription: "Date string non valida: \(dateString)"
                )
            }
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case id, date, amount, type, currency
        case description, category, notes, counterparty
        case originalID, bankSource
    }
}

// MARK: - Sample Data

extension BankTransaction {
    /// Transazione di esempio per preview/testing
    static var sample: BankTransaction {
        BankTransaction(
            date: Date(),
            amount: 89.50,
            type: .expense,
            currency: .EUR,
            description: "Pagamento bolletta luce",
            category: "Utenze",
            notes: "Consumo ottobre 2024",
            counterparty: "Enel Energia",
            originalID: "TRX-2024-001234",
            bankSource: "Intesa Sanpaolo"
        )
    }
    
    /// Array di transazioni di esempio
    static var samples: [BankTransaction] {
        [
            BankTransaction(
                date: Date().addingTimeInterval(-86400 * 5),
                amount: 89.50,
                type: .expense,
                description: "Bolletta Luce",
                category: "Utenze",
                counterparty: "Enel Energia",
                bankSource: "Intesa Sanpaolo"
            ),
            BankTransaction(
                date: Date().addingTimeInterval(-86400 * 3),
                amount: 156.20,
                type: .expense,
                description: "Bolletta Gas",
                category: "Utenze",
                counterparty: "ENI Gas e Luce",
                bankSource: "Intesa Sanpaolo"
            ),
            BankTransaction(
                date: Date().addingTimeInterval(-86400 * 1),
                amount: 2500.00,
                type: .income,
                description: "Stipendio Mensile",
                category: "Reddito",
                counterparty: "Azienda XYZ Srl",
                bankSource: "Intesa Sanpaolo"
            )
        ]
    }
}
