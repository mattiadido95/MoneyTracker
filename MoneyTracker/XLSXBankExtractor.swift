//
//  XLSXBankExtractor.swift
//  MoneyTracker
//
//  Created by Assistant on 14/12/25.
//

/*
 EXTRACTOR - XLSX Bank Statement Reader
 
 Responsabilità: Leggere file XLSX e restituire righe grezze
 
 DESIGN:
 • Usa CoreXLSX per parsing Excel nativo
 • NON conosce strutture bancarie specifiche
 • Restituisce dati grezzi come stringhe
 • Zero business logic, solo I/O
 
 UTILIZZO:
 let extractor = XLSXBankExtractor()
 let rows = try await extractor.extract(from: fileURL)
 // rows contiene array di RawBankRow con data/descrizione/importo come String
*/

import Foundation

#if canImport(CoreXLSX)
import CoreXLSX
#else
// Stub types per permettere compilazione senza CoreXLSX
// Installare CoreXLSX per funzionalità complete: https://github.com/CoreOffice/CoreXLSX
fileprivate struct XLSXFile {
    init?(filepath: String) { return nil }
    func parseWorksheetPaths() throws -> [String]? { return nil }
    func parseWorksheet(at path: String) throws -> Worksheet { fatalError("CoreXLSX non installato") }
    func parseSharedStrings() throws -> SharedStrings? { return nil }
}
fileprivate struct Worksheet {
    var data: WorksheetData? { return nil }
}
fileprivate struct WorksheetData {
    var rows: [Row] { return [] }
}
fileprivate struct Row {
    var cells: [Cell] { return [] }
}
fileprivate struct Cell {
    var reference: CellReference { CellReference() }
    var value: String? { return nil }
    var inlineString: InlineString? { return nil }
    var formula: Formula? { return nil }
    func stringValue(_ sharedStrings: SharedStrings?) -> Int? { return nil }
}
fileprivate struct CellReference {
    var column: ColumnReference { ColumnReference() }
}
fileprivate struct ColumnReference {
    var value: String { return "A" }
}
fileprivate struct InlineString {
    var text: String? { return nil }
}
fileprivate struct Formula {
    var value: String? { return nil }
}
fileprivate struct SharedStrings {
    var items: [SharedStringItem] { return [] }
}
fileprivate struct SharedStringItem {
    var text: String? { return nil }
}
#endif

// MARK: - RawBankRow

/// Rappresentazione grezza di una riga del file bancario
///
/// Contiene solo stringhe grezze, nessun parsing o interpretazione.
/// La trasformazione in tipi Swift (Date, Double) è responsabilità del Transformer.
struct RawBankRow {
    /// Numero di riga nel file (utile per error reporting)
    let rowIndex: Int
    
    /// Tutti i valori della riga indicizzati per colonna
    /// Key: nome colonna o indice (es: "A", "B", "Data", "Importo")
    /// Value: valore stringa grezza
    let columns: [String: String]
    
    /// Accesso conveniente ai campi comuni (se presenti)
    var date: String? {
        columns["date"] ?? columns["Data"] ?? columns["data"]
    }
    
    var transactionDescription: String? {
        columns["description"] ?? columns["Descrizione"] ?? columns["descrizione"]
    }
    
    var amount: String? {
        columns["amount"] ?? columns["Importo"] ?? columns["importo"]
    }
    
    /// Accesso a valore per chiave case-insensitive
    func value(forKey key: String) -> String? {
        // Cerca esattamente
        if let value = columns[key] {
            return value
        }
        
        // Cerca case-insensitive
        let lowercasedKey = key.lowercased()
        for (columnKey, columnValue) in columns {
            if columnKey.lowercased() == lowercasedKey {
                return columnValue
            }
        }
        
        return nil
    }
    
    /// Verifica se la riga è vuota
    var isEmpty: Bool {
        columns.values.allSatisfy { $0.trimmingCharacters(in: .whitespaces).isEmpty }
    }
}

// MARK: - XLSXBankExtractor

/// Extractor per file XLSX bancari
///
/// Legge il primo foglio del file e restituisce righe grezze.
/// Non interpreta i dati, solo estrae stringhe.
class XLSXBankExtractor: BankExtractor {
    
    // MARK: - BankExtractor Conformance
    
    var supportedFormats: [String] {
        ["xlsx", "xls"]
    }
    
    // MARK: - Configuration
    
    /// Numero minimo di colonne per considerare una riga valida
    var minimumColumnCount: Int = 2
    
    /// Salta righe vuote
    var skipEmptyRows: Bool = true
    
    /// Numero di riga da cui iniziare (0-based, default 0 = prima riga)
    var startRow: Int = 0
    
    /// Usa la prima riga come header
    var firstRowAsHeader: Bool = true
    
    // MARK: - Extract Implementation
    
    func extract(from fileURL: URL) async throws -> [[String: Any]] {
        // Verifica accesso al file
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            throw BankImportError.fileNotFound
        }
        
        // Verifica formato
        let fileExtension = fileURL.pathExtension.lowercased()
        guard supportedFormats.contains(fileExtension) else {
            throw BankImportError.invalidFileFormat
        }
        
        // Parsing XLSX
        let rows = try await parseXLSX(fileURL: fileURL)
        
        // Converti RawBankRow in [[String: Any]] per compatibilità protocol
        let rawData = rows.map { row -> [String: Any] in
            var dict: [String: Any] = [:]
            dict["rowIndex"] = row.rowIndex
            for (key, value) in row.columns {
                dict[key] = value
            }
            return dict
        }
        
        return rawData
    }
    
    // MARK: - Public Methods
    
    /// Estrae righe grezze dal file XLSX
    /// - Parameter fileURL: URL del file .xlsx
    /// - Returns: Array di RawBankRow
    func extractRows(from fileURL: URL) async throws -> [RawBankRow] {
        return try await parseXLSX(fileURL: fileURL)
    }
    
    // MARK: - Private Methods
    
    private func parseXLSX(fileURL: URL) async throws -> [RawBankRow] {
        return try await withCheckedThrowingContinuation { continuation in
            do {
                // Apri file XLSX
                guard let file = XLSXFile(filepath: fileURL.path) else {
                    continuation.resume(throwing: BankImportError.invalidFileFormat)
                    return
                }
                
                // Ottieni il primo foglio
                guard let worksheetPaths = try file.parseWorksheetPaths(),
                      let firstWorksheetPath = worksheetPaths.first else {
                    continuation.resume(throwing: BankImportError.emptyFile)
                    return
                }
                
                // Parse worksheet
                let worksheet = try file.parseWorksheet(at: firstWorksheetPath)
                
                // Parse shared strings (per celle con riferimenti)
                let sharedStrings = try file.parseSharedStrings()
                
                // Estrai righe
                let rows = try extractRows(
                    from: worksheet,
                    sharedStrings: sharedStrings
                )
                
                continuation.resume(returning: rows)
                
            } catch let error as BankImportError {
                continuation.resume(throwing: error)
            } catch {
                continuation.resume(throwing: BankImportError.parsingFailed(
                    details: error.localizedDescription
                ))
            }
        }
    }
    
    private func extractRows(
        from worksheet: Worksheet,
        sharedStrings: SharedStrings?
    ) throws -> [RawBankRow] {
        
        guard let sheetData = worksheet.data else {
            throw BankImportError.emptyFile
        }
        
        var result: [RawBankRow] = []
        var headerColumns: [String: Int]? = nil // nome colonna → indice
        
        // Itera sulle righe
        for (index, row) in sheetData.rows.enumerated() {
            // Salta righe prima di startRow
            guard index >= startRow else { continue }
            
            // Estrai valori celle
            var columns: [String: String] = [:]
            
            for cell in row.cells {
                let columnLetter = cell.reference.column.value
                let cellValue = getCellValue(cell, sharedStrings: sharedStrings)
                
                // Se abbiamo header, usa nomi colonne
                if let headers = headerColumns {
                    if let columnIndex = columnIndex(from: columnLetter),
                       let headerName = headers.first(where: { $0.value == columnIndex })?.key {
                        columns[headerName] = cellValue
                    } else {
                        columns[columnLetter] = cellValue
                    }
                } else {
                    columns[columnLetter] = cellValue
                }
            }
            
            // Prima riga come header
            if firstRowAsHeader && index == startRow {
                headerColumns = [:]
                for (key, value) in columns {
                    if let colIndex = columnIndex(from: key) {
                        headerColumns?[value] = colIndex
                    }
                }
                continue // Salta header, non includerla nei dati
            }
            
            // Crea RawBankRow
            let rawRow = RawBankRow(rowIndex: index, columns: columns)
            
            // Salta righe vuote se configurato
            if skipEmptyRows && rawRow.isEmpty {
                continue
            }
            
            // Verifica minimo colonne
            if columns.count < minimumColumnCount {
                continue
            }
            
            result.append(rawRow)
        }
        
        // Verifica che ci siano dati
        guard !result.isEmpty else {
            throw BankImportError.emptyFile
        }
        
        return result
    }
    
    private func getCellValue(_ cell: Cell, sharedStrings: SharedStrings?) -> String {
        // Gestisci diversi tipi di celle
        if let sharedStringIndex = cell.stringValue(sharedStrings),
           let value = sharedStrings?.items[sharedStringIndex].text {
            return value
        }
        
        // Valore inline string
        if let inlineString = cell.inlineString {
            return inlineString.text ?? ""
        }
        
        // Valore numerico o data
        if let value = cell.value {
            return value
        }
        
        // Formula (restituisci risultato se disponibile)
        if let formula = cell.formula,
           let cachedValue = formula.value {
            return cachedValue
        }
        
        return ""
    }
    
    /// Converte lettera colonna (A, B, AA) in indice numerico (0, 1, 26)
    private func columnIndex(from letter: String) -> Int? {
        var result = 0
        for char in letter.uppercased() {
            guard let scalar = char.unicodeScalars.first,
                  scalar >= "A" && scalar <= "Z" else {
                return nil
            }
            result = result * 26 + (Int(scalar.value) - Int(UnicodeScalar("A").value) + 1)
        }
        return result - 1 // 0-based
    }
}

// MARK: - Extensions

extension RawBankRow: CustomStringConvertible {
    var description: String {
        let columnsStr = columns.map { "\($0): \($1)" }.joined(separator: ", ")
        return "RawBankRow(row: \(rowIndex), {\(columnsStr)})"
    }
}

// MARK: - Convenience Initializers

extension XLSXBankExtractor {
    /// Crea extractor con configurazione custom
    convenience init(
        startRow: Int = 0,
        firstRowAsHeader: Bool = true,
        skipEmptyRows: Bool = true,
        minimumColumnCount: Int = 2
    ) {
        self.init()
        self.startRow = startRow
        self.firstRowAsHeader = firstRowAsHeader
        self.skipEmptyRows = skipEmptyRows
        self.minimumColumnCount = minimumColumnCount
    }
}
