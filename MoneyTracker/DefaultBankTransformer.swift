//
//  DefaultBankTransformer.swift
//  MoneyTracker
//
//  Created by Assistant on 14/12/25.
//

/*
 TRANSFORMER - Default Bank Row Transformer
 
 Responsabilità: Convertire RawBankRow in BankTransaction normalizzate
 
 DESIGN:
 • Funzioni pure e testabili
 • Zero side effects
 • Parsing robusto con fallback
 • Normalizzazione stringhe
 • Riconoscimento automatico entrate/uscite
 
 UTILIZZO:
 let transformer = DefaultBankTransformer(bankName: "Intesa Sanpaolo")
 let transaction = try transformer.transformRow(rawRow, columnMapping: mapping)
*/

import Foundation

// MARK: - Column Mapping

/// Configurazione mapping colonne da file a campi BankTransaction
struct BankColumnMapping {
    let dateColumn: String
    let descriptionColumn: String
    let amountColumn: String
    let notesColumn: String?
    let counterpartyColumn: String?
    let categoryColumn: String?
    
    /// Mapping di default (nomi colonne italiani)
    static var `default`: BankColumnMapping {
        BankColumnMapping(
            dateColumn: "Data",
            descriptionColumn: "Descrizione",
            amountColumn: "Importo",
            notesColumn: nil,
            counterpartyColumn: nil,
            categoryColumn: nil
        )
    }
    
    /// Mapping con nomi inglesi
    static var english: BankColumnMapping {
        BankColumnMapping(
            dateColumn: "Date",
            descriptionColumn: "Description",
            amountColumn: "Amount",
            notesColumn: "Notes",
            counterpartyColumn: "Counterparty",
            categoryColumn: "Category"
        )
    }
}

// MARK: - DefaultBankTransformer

/// Transformer generico per conversione RawBankRow → BankTransaction
class DefaultBankTransformer {
    
    // MARK: - Properties
    
    /// Nome della banca di origine
    let bankName: String
    
    /// Valuta di default
    let defaultCurrency: Currency
    
    /// Formati date supportati (in ordine di priorità)
    let dateFormats: [String]
    
    /// Separatori decimali supportati per importi
    let decimalSeparators: [String]
    
    // MARK: - Initialization
    
    init(
        bankName: String,
        defaultCurrency: Currency = .EUR,
        dateFormats: [String] = DateParser.defaultFormats,
        decimalSeparators: [String] = [".", ","]
    ) {
        self.bankName = bankName
        self.defaultCurrency = defaultCurrency
        self.dateFormats = dateFormats
        self.decimalSeparators = decimalSeparators
    }
    
    // MARK: - Transformation
    
    /// Trasforma una riga grezza in BankTransaction
    /// - Parameters:
    ///   - row: Riga grezza dal file
    ///   - mapping: Configurazione mapping colonne
    /// - Returns: BankTransaction normalizzata
    /// - Throws: Errore se campi obbligatori mancanti o non parsabili
    func transformRow(
        _ row: RawBankRow,
        columnMapping: BankColumnMapping = .default
    ) throws -> BankTransaction {
        
        // Estrai valori dalle colonne
        guard let dateString = row.value(forKey: columnMapping.dateColumn),
              !dateString.isEmpty else {
            throw BankImportError.missingRequiredField(field: "Data")
        }
        
        guard let descriptionString = row.value(forKey: columnMapping.descriptionColumn),
              !descriptionString.isEmpty else {
            throw BankImportError.missingRequiredField(field: "Descrizione")
        }
        
        guard let amountString = row.value(forKey: columnMapping.amountColumn),
              !amountString.isEmpty else {
            throw BankImportError.missingRequiredField(field: "Importo")
        }
        
        // Parse date
        guard let date = parseDate(dateString, formats: dateFormats) else {
            throw BankImportError.dateParsingFailed(value: dateString)
        }
        
        // Parse amount
        guard let (amount, type) = parseAmount(amountString, decimalSeparators: decimalSeparators) else {
            throw BankImportError.amountParsingFailed(value: amountString)
        }
        
        // Normalize description
        let description = normalizeDescription(descriptionString)
        
        // Campi opzionali
        let notes = columnMapping.notesColumn
            .flatMap { row.value(forKey: $0) }
            .map { normalizeDescription($0) }
        
        let counterparty = columnMapping.counterpartyColumn
            .flatMap { row.value(forKey: $0) }
            .map { normalizeDescription($0) }
        
        let category = columnMapping.categoryColumn
            .flatMap { row.value(forKey: $0) }
            .map { normalizeDescription($0) }
        
        // Crea transaction
        return BankTransaction(
            date: date,
            amount: amount,
            type: type,
            currency: defaultCurrency,
            description: description,
            category: category,
            notes: notes,
            counterparty: counterparty,
            originalID: nil,
            bankSource: bankName
        )
    }
    
    /// Trasforma array di righe in array di transazioni
    /// - Parameters:
    ///   - rows: Array di righe grezze
    ///   - mapping: Configurazione mapping colonne
    /// - Returns: Array di BankTransaction
    func transformRows(
        _ rows: [RawBankRow],
        columnMapping: BankColumnMapping = .default
    ) throws -> [BankTransaction] {
        var transactions: [BankTransaction] = []
        var errors: [BankImportError] = []
        
        for row in rows {
            do {
                let transaction = try transformRow(row, columnMapping: columnMapping)
                transactions.append(transaction)
            } catch let error as BankImportError {
                errors.append(error)
            }
        }
        
        // Se troppi errori, fallisce
        if errors.count > rows.count / 2 {
            throw BankImportError.parsingFailed(
                details: "Troppe righe non valide: \(errors.count)/\(rows.count)"
            )
        }
        
        return transactions
    }
}

// MARK: - Pure Functions

/// Funzioni pure per parsing e normalizzazione
/// Tutte testabili in isolamento

// MARK: Date Parsing

struct DateParser {
    /// Formati data italiani comuni
    static let defaultFormats = [
        "dd/MM/yyyy",           // 15/10/2024
        "dd-MM-yyyy",           // 15-10-2024
        "yyyy-MM-dd",           // 2024-10-15 (ISO)
        "dd/MM/yy",             // 15/10/24
        "dd-MM-yy",             // 15-10-24
        "dd.MM.yyyy",           // 15.10.2024
        "yyyy/MM/dd",           // 2024/10/15
        "dd MMM yyyy",          // 15 Ott 2024
        "dd MMMM yyyy",         // 15 Ottobre 2024
        "yyyyMMdd"              // 20241015
    ]
}

/// Parse una data da stringa con multiple formati
/// - Parameters:
///   - dateString: Stringa da parsare
///   - formats: Array di formati da provare
/// - Returns: Date se parsata con successo, nil altrimenti
func parseDate(_ dateString: String, formats: [String] = DateParser.defaultFormats) -> Date? {
    let trimmed = dateString.trimmingCharacters(in: .whitespacesAndNewlines)
    
    // Prova con ISO8601 (formato standard)
    let isoFormatter = ISO8601DateFormatter()
    if let date = isoFormatter.date(from: trimmed) {
        return date
    }
    
    // Prova con formati custom
    let dateFormatter = DateFormatter()
    dateFormatter.locale = Locale(identifier: "it_IT")
    dateFormatter.timeZone = TimeZone.current
    
    for format in formats {
        dateFormatter.dateFormat = format
        if let date = dateFormatter.date(from: trimmed) {
            return date
        }
    }
    
    // Fallback: prova con locale US
    dateFormatter.locale = Locale(identifier: "en_US")
    for format in formats {
        dateFormatter.dateFormat = format
        if let date = dateFormatter.date(from: trimmed) {
            return date
        }
    }
    
    return nil
}

// MARK: Amount Parsing

/// Parse un importo da stringa e determina il tipo di transazione
/// - Parameters:
///   - amountString: Stringa da parsare (es: "89,50", "-156.20", "€ 2.500,00")
///   - decimalSeparators: Separatori decimali supportati
/// - Returns: Tupla (importo assoluto, tipo transazione) o nil se parsing fallisce
func parseAmount(
    _ amountString: String,
    decimalSeparators: [String] = [".", ","]
) -> (amount: Double, type: TransactionType)? {
    
    var cleaned = amountString
        .trimmingCharacters(in: .whitespacesAndNewlines)
    
    // Rimuovi simboli valuta comuni
    let currencySymbols = ["€", "$", "£", "EUR", "USD", "GBP", "CHF"]
    for symbol in currencySymbols {
        cleaned = cleaned.replacingOccurrences(of: symbol, with: "")
    }
    
    // Rimuovi spazi
    cleaned = cleaned.replacingOccurrences(of: " ", with: "")
    
    // Determina se è negativo
    let isNegative = cleaned.hasPrefix("-") || cleaned.hasPrefix("(")
    
    // Rimuovi segni
    cleaned = cleaned.replacingOccurrences(of: "-", with: "")
    cleaned = cleaned.replacingOccurrences(of: "+", with: "")
    cleaned = cleaned.replacingOccurrences(of: "(", with: "")
    cleaned = cleaned.replacingOccurrences(of: ")", with: "")
    
    // Normalizza separatori
    // Logica: se contiene sia punto che virgola, l'ultimo è il decimale
    let hasPoint = cleaned.contains(".")
    let hasComma = cleaned.contains(",")
    
    if hasPoint && hasComma {
        // Determina quale è il decimale (l'ultimo che appare)
        if let lastPointIndex = cleaned.lastIndex(of: "."),
           let lastCommaIndex = cleaned.lastIndex(of: ",") {
            
            if lastCommaIndex > lastPointIndex {
                // Virgola è decimale, punto è migliaia
                cleaned = cleaned.replacingOccurrences(of: ".", with: "")
                cleaned = cleaned.replacingOccurrences(of: ",", with: ".")
            } else {
                // Punto è decimale, virgola è migliaia
                cleaned = cleaned.replacingOccurrences(of: ",", with: "")
            }
        }
    } else if hasComma {
        // Solo virgola → assume decimale
        cleaned = cleaned.replacingOccurrences(of: ",", with: ".")
    }
    // Se solo punto, già OK
    
    // Parse finale
    guard let amount = Double(cleaned), amount >= 0 else {
        return nil
    }
    
    // Determina tipo transazione
    let type: TransactionType = isNegative ? .expense : .income
    
    return (amount, type)
}

// MARK: Description Normalization

/// Normalizza una descrizione rimuovendo whitespace e caratteri inutili
/// - Parameter description: Stringa da normalizzare
/// - Returns: Stringa normalizzata
func normalizeDescription(_ description: String) -> String {
    var normalized = description
        .trimmingCharacters(in: .whitespacesAndNewlines)
    
    // Rimuovi spazi multipli
    while normalized.contains("  ") {
        normalized = normalized.replacingOccurrences(of: "  ", with: " ")
    }
    
    // Rimuovi line breaks
    normalized = normalized.replacingOccurrences(of: "\n", with: " ")
    normalized = normalized.replacingOccurrences(of: "\r", with: " ")
    normalized = normalized.replacingOccurrences(of: "\t", with: " ")
    
    // Capitalizza prima lettera se tutto minuscolo o maiuscolo
    if normalized.lowercased() == normalized || normalized.uppercased() == normalized {
        normalized = normalized.capitalized
    }
    
    return normalized
}

// MARK: Transaction Type Detection

/// Inferisce il tipo di transazione dalla descrizione
/// - Parameter description: Descrizione transazione
/// - Returns: Tipo inferito (expense di default se incerto)
func inferTransactionType(from description: String) -> TransactionType {
    let lowercased = description.lowercased()
    
    // Keywords per entrate
    let incomeKeywords = [
        "stipendio", "salary", "bonifico in entrata", "accredito",
        "income", "deposit", "credit", "refund", "rimborso"
    ]
    
    for keyword in incomeKeywords {
        if lowercased.contains(keyword) {
            return .income
        }
    }
    
    // Keywords per uscite
    let expenseKeywords = [
        "pagamento", "addebito", "prelievo", "bolletta",
        "payment", "withdrawal", "debit", "charge"
    ]
    
    for keyword in expenseKeywords {
        if lowercased.contains(keyword) {
            return .expense
        }
    }
    
    // Default: assume spesa se non si capisce
    return .expense
}

// MARK: - Category Inference

/// Inferisce categoria da descrizione (AI-ready)
/// - Parameter description: Descrizione transazione
/// - Returns: Categoria inferita o nil
func inferCategory(from description: String) -> String? {
    let lowercased = description.lowercased()
    
    // Mapping keywords → categoria
    let categoryMap: [String: [String]] = [
        "Utenze": ["luce", "gas", "acqua", "elettricità", "enel", "eni", "acea"],
        "Telecomunicazioni": ["telefono", "internet", "mobile", "tim", "vodafone", "wind"],
        "Trasporti": ["benzina", "gasolio", "carburante", "autostrada", "treno", "metro"],
        "Alimentari": ["supermercato", "spesa", "conad", "coop", "esselunga", "carrefour"],
        "Ristorazione": ["ristorante", "bar", "pizzeria", "trattoria", "mcdonald"],
        "Salute": ["farmacia", "medico", "ospedale", "dentista", "visita"],
        "Affitto": ["affitto", "rent", "canone locazione"],
        "Intrattenimento": ["cinema", "teatro", "netflix", "spotify", "amazon prime"],
        "Abbigliamento": ["zara", "h&m", "decathlon", "abbigliamento"]
    ]
    
    // Cerca match
    for (category, keywords) in categoryMap {
        for keyword in keywords {
            if lowercased.contains(keyword) {
                return category
            }
        }
    }
    
    return nil
}

// MARK: - Testing Helpers

#if DEBUG
extension DefaultBankTransformer {
    /// Crea transformer per testing
    static var mock: DefaultBankTransformer {
        DefaultBankTransformer(bankName: "Test Bank")
    }
}

// Test data per unit tests
extension RawBankRow {
    static var sample: RawBankRow {
        RawBankRow(
            rowIndex: 1,
            columns: [
                "Data": "15/10/2024",
                "Descrizione": "Pagamento Bolletta Luce",
                "Importo": "-89,50"
            ]
        )
    }
    
    static var sampleIncome: RawBankRow {
        RawBankRow(
            rowIndex: 2,
            columns: [
                "Data": "2024-10-20",
                "Descrizione": "Accredito Stipendio",
                "Importo": "2.500,00"
            ]
        )
    }
}
#endif
