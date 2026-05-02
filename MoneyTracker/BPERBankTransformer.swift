//
//  BPERBankTransformer.swift
//  MoneyTracker
//

/*
 TRANSFORMER - BPER Banca

 Responsabilità: Convertire RawBankRow BPER in BankTransaction normalizzate

 DIFFERENZE RISPETTO AL TRANSFORMER GENERICO:
 • Entrate e Uscite su colonne separate (non singolo "Importo")
 • Date in formato italiano testuale: "31 dicembre 2025"
 • Categorie bancarie BPER: BANCOMAT, BONIFICO, PAGAMENTO, COMMISSIONE, ecc.
 • Locale it_IT obbligatorio per parsing date

 MAPPING COLONNE BPER:
 ┌──────────────────┬───────────────────────────────────────┐
 │ Colonna file     │ Campo BankTransaction                 │
 ├──────────────────┼───────────────────────────────────────┤
 │ Data operazione  │ date                                  │
 │ Descrizione      │ description                           │
 │ Entrate          │ amount + type = .income               │
 │ Uscite           │ amount (abs) + type = .expense        │
 │ Categoria        │ category (mappata)                    │
 └──────────────────┴───────────────────────────────────────┘

 UTILIZZO:
 let transformer = BPERBankTransformer()
 let transaction = try transformer.transformRow(row)
 */

import Foundation

// MARK: - BPERBankTransformer

class BPERBankTransformer: DefaultBankTransformer {

    // MARK: - Nomi colonne BPER

    static let colDataOperazione = "Data operazione"
    static let colDescrizione    = "Descrizione"
    static let colEntrate        = "Entrate"
    static let colUscite         = "Uscite"
    static let colCategoria      = "Categoria"
    /// Carta prepagata BPER: colonna unica con segno (negativo = spesa, positivo = ricarica)
    static let colImporto        = "Importo €"

    // MARK: - Init

    init() {
        super.init(
            bankName: "BPER Banca",
            defaultCurrency: .EUR,
            dateFormats: [
                "dd MMMM yyyy",   // 31 dicembre 2025  ← formato BPER principale
                "dd/MM/yyyy",     // 31/12/2025
                "dd-MM-yyyy",     // 31-12-2025
                "yyyy-MM-dd"      // 2025-12-31 (ISO)
            ]
        )
    }

    // MARK: - Identificatori banca

    var bankIdentifiers: [String] {
        ["BPER", "bper", "Movimenti Conto", "Data operazione"]
    }

    // MARK: - Override transformRow

    /// Trasforma una riga BPER in BankTransaction
    /// Ignora il columnMapping del generico: usa sempre le colonne BPER fisse.
    override func transformRow(
        _ row: RawBankRow,
        columnMapping: BankColumnMapping = .default
    ) throws -> BankTransaction {

        // ── 1. Data ──────────────────────────────────────────────────────────
        guard let dateString = row.value(forKey: Self.colDataOperazione),
              !dateString.isEmpty else {
            throw BankImportError.missingRequiredField(field: Self.colDataOperazione)
        }
        guard let date = parseDateItalian(dateString) else {
            throw BankImportError.dateParsingFailed(value: dateString)
        }

        // ── 2. Descrizione ───────────────────────────────────────────────────
        guard let rawDescription = row.value(forKey: Self.colDescrizione),
              !rawDescription.isEmpty else {
            throw BankImportError.missingRequiredField(field: Self.colDescrizione)
        }
        let description = normalizeDescription(rawDescription)

        // ── 3. Importo + Tipo ───────────────────────────────────────────────
        // Due formati BPER supportati:
        //   • Conto Corrente: colonne separate "Entrate" e "Uscite"
        //   • Carta Prepagata: colonna unica "Importo €" (positivo = ricarica, negativo = spesa)
        let entrateStr = row.value(forKey: Self.colEntrate) ?? ""
        let usciteStr  = row.value(forKey: Self.colUscite)  ?? ""
        let importoStr = row.value(forKey: Self.colImporto) ?? ""

        let amount: Double
        let type: TransactionType

        if let entrate = parseNumericAmount(entrateStr), entrate > 0 {
            // Conto Corrente: entrata
            amount = entrate
            type   = .income
        } else if let uscite = parseNumericAmount(usciteStr), uscite != 0 {
            // Conto Corrente: uscita
            amount = abs(uscite)
            type   = .expense
        } else if let importo = parseNumericAmount(importoStr), importo != 0 {
            // Carta Prepagata: importo unico con segno
            amount = abs(importo)
            type   = importo < 0 ? .expense : .income
        } else {
            throw BankImportError.missingRequiredField(field: "Entrate/Uscite/Importo")
        }

        // ── 4. Categoria ─────────────────────────────────────────────────────
        let rawCategory = row.value(forKey: Self.colCategoria)
        let category    = rawCategory
            .flatMap { $0.isEmpty ? nil : $0 }
            .map { mapBPERCategory($0) }

        // ── 5. Costruisci BankTransaction ────────────────────────────────────
        return BankTransaction(
            date:         date,
            amount:       amount,
            type:         type,
            currency:     defaultCurrency,
            description:  description,
            category:     category,
            notes:        nil,
            counterparty: nil,
            originalID:   nil,
            bankSource:   bankName
        )
    }

    // MARK: - Private: Date Parsing (it_IT)

    /// Parser con Locale italiano fisso, ottimizzato per "dd MMMM yyyy"
    private func parseDateItalian(_ string: String) -> Date? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)

        let formatter = DateFormatter()
        formatter.locale   = Locale(identifier: "it_IT")
        formatter.timeZone = TimeZone.current

        for format in dateFormats {
            formatter.dateFormat = format
            if let date = formatter.date(from: trimmed) {
                return date
            }
        }
        return nil
    }

    // MARK: - Private: Amount Parsing

    /// Parse un numero che può arrivare come "-30.45", "-130", "150.0"
    /// (Python xlrd restituisce valori già in notazione anglosassone)
    private func parseNumericAmount(_ string: String) -> Double? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return Double(trimmed)
    }

    // MARK: - Private: Categoria BPER → MoneyTracker

    /// Mappa le categorie BPER alle categorie di MoneyTracker
    private func mapBPERCategory(_ bperCategory: String) -> String {
        switch bperCategory.uppercased() {
        case "BANCOMAT":                return "Prelievo"
        case "BONIFICO":                return "Bonifico"
        case "PAGAMENTO":               return "Pagamento"
        case "COMMISSIONE":             return "Commissioni"
        case "ACCREDITO STIPENDIO",
             "STIPENDIO":               return "Stipendio"
        case "F24":                     return "Tasse"
        case "RATA MUTUO",
             "MUTUO":                   return "Mutuo"
        case "RICARICA":                return "Ricarica"
        case "ADDEBITO UTENZA",
             "UTENZA":                  return "Utenze"
        default:                        return bperCategory.capitalized
        }
    }
}

// MARK: - BankColumnMapping BPER

extension BankColumnMapping {
    /// Mapping colonne per BPER Banca
    /// Nota: amountColumn non viene usato da BPERBankTransformer
    /// (gestisce Entrate/Uscite internamente), ma è richiesto dalla struttura.
    static var bper: BankColumnMapping {
        BankColumnMapping(
            dateColumn:        BPERBankTransformer.colDataOperazione,
            descriptionColumn: BPERBankTransformer.colDescrizione,
            amountColumn:      BPERBankTransformer.colUscite,
            notesColumn:       nil,
            counterpartyColumn: nil,
            categoryColumn:    BPERBankTransformer.colCategoria
        )
    }
}
