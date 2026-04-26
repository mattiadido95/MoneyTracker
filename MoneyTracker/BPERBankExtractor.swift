//
//  BPERBankExtractor.swift
//  MoneyTracker
//

/*
 EXTRACTOR - BPER Banca XLS Reader

 Responsabilità: Leggere file XLS di BPER e restituire righe grezze

 STRUTTURA FILE BPER:
 • Righe 0–15: metadati (intestatario, IBAN, saldi, periodo)
 • Riga 16:    header colonne → "Data operazione", "Data valuta",
               "Descrizione", "Entrate", "Uscite", "Categoria"
 • Righe 17+:  transazioni effettive

 FORMATO FILE:
 • .xls binario (BIFF8 / OLE2) → parse via Python xlrd
 • .xlsx (se disponibile) → delegato a XLSXBankExtractor con startRow=16

 UTILIZZO:
 let extractor = BPERBankExtractor()
 let rows = try await extractor.extractRows(from: fileURL)
 */

import Foundation

// MARK: - BPERBankExtractor

class BPERBankExtractor: BankExtractor {

    // MARK: - Costanti

    /// Riga (0-indexed) che contiene gli header nel file BPER
    /// (righe 0-16 sono metadati, riga 17 = "Data operazione | Descrizione | ...")
    static let headerRow = 17

    /// Prima riga dati (0-indexed)
    static let firstDataRow = 18

    // MARK: - BankExtractor Conformance

    var supportedFormats: [String] { ["xls", "xlsx"] }

    func extract(from fileURL: URL) async throws -> [[String: Any]] {
        let rows = try await extractRows(from: fileURL)
        return rows.map { row -> [String: Any] in
            var dict: [String: Any] = ["rowIndex": row.rowIndex]
            for (k, v) in row.columns { dict[k] = v }
            return dict
        }
    }

    // MARK: - Public

    /// Estrae righe grezze dal file, già con nomi colonne BPER
    func extractRows(from fileURL: URL) async throws -> [RawBankRow] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            throw BankImportError.fileNotFound
        }

        let ext = fileURL.pathExtension.lowercased()
        guard supportedFormats.contains(ext) else {
            throw BankImportError.invalidFileFormat
        }

        if ext == "xls" {
            return try await extractFromXLS(fileURL: fileURL)
        } else {
            // xlsx: usa XLSXBankExtractor già configurato con lo startRow corretto
            // startRow = headerRow: XLSXBankExtractor usa questa riga come header
            // e legge i dati dalle righe successive
            let xlsxExtractor = XLSXBankExtractor(
                startRow: Self.headerRow,
                firstRowAsHeader: true,
                skipEmptyRows: true,
                minimumColumnCount: 2
            )
            return try await xlsxExtractor.extractRows(from: fileURL)
        }
    }

    // MARK: - Private: XLS via Python

    private func extractFromXLS(fileURL: URL) async throws -> [RawBankRow] {
#if os(macOS)
        return try await withCheckedThrowingContinuation { continuation in
            do {
                let scriptURL = try writePythonScript()
                let output = try runPython(scriptURL: scriptURL, xlsPath: fileURL.path)
                let rows = try parseJSON(output)
                continuation.resume(returning: rows)
            } catch let e as BankImportError {
                continuation.resume(throwing: e)
            } catch {
                continuation.resume(throwing: BankImportError.parsingFailed(
                    details: error.localizedDescription
                ))
            }
        }
#else
        // Su iOS Process non è disponibile: XLS richiede macOS
        throw BankImportError.parsingFailed(
            details: "Importazione file .xls supportata solo su macOS. " +
                     "Salva il file come .xlsx dalla tua banca e riprova."
        )
#endif
    }

#if os(macOS)
    /// Script Python che legge il file XLS e restituisce le righe come JSON
    private func writePythonScript() throws -> URL {
        let script = """
import xlrd, json, sys

wb = xlrd.open_workbook(sys.argv[1])
ws = wb.sheet_by_index(0)
header_row = \(Self.headerRow)
first_data_row = \(Self.firstDataRow)

headers = []
for j in range(ws.ncols):
    v = ws.cell(header_row, j).value
    headers.append(str(v).strip() if v else "col_{}".format(j))

rows = []
for i in range(first_data_row, ws.nrows):
    row = {}
    for j, h in enumerate(headers):
        c = ws.cell(i, j)
        if c.ctype == 0:
            row[h] = ""
        elif c.ctype == 1:
            row[h] = str(c.value).strip()
        elif c.ctype == 2:
            v = c.value
            row[h] = str(int(v)) if v == int(v) else str(v)
        else:
            row[h] = str(c.value).strip()
    rows.append(row)

print(json.dumps(rows, ensure_ascii=False))
"""
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("bper_extract.py")
        try script.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    private func runPython(scriptURL: URL, xlsPath: String) throws -> Data {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["python3", scriptURL.path, xlsPath]

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            let errMsg = String(
                data: stderrPipe.fileHandleForReading.readDataToEndOfFile(),
                encoding: .utf8
            ) ?? "errore sconosciuto"
            throw BankImportError.parsingFailed(
                details: "Python exit \(process.terminationStatus): \(errMsg)"
            )
        }

        return stdoutPipe.fileHandleForReading.readDataToEndOfFile()
    }
#endif

    private func parseJSON(_ data: Data) throws -> [RawBankRow] {
        guard let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: String]] else {
            throw BankImportError.parsingFailed(details: "Output Python non è un JSON valido")
        }

        let rows: [RawBankRow] = jsonArray.enumerated().compactMap { (offset, dict) in
            // Salta righe completamente vuote
            let hasContent = dict.values.contains { !$0.isEmpty }
            guard hasContent else { return nil }
            return RawBankRow(rowIndex: Self.firstDataRow + offset, columns: dict)
        }

        guard !rows.isEmpty else {
            throw BankImportError.emptyFile
        }

        return rows
    }
}
