//
//  ExportImportManager.swift
//  MoneyTracker
//
//  Created by Assistant on 09/12/24.
//

/*
 SERVICE - ExportImportManager (Gestore Export/Import)
 
 Questo servizio gestisce l'export e import dei dati JSON per backup e condivisione.
 
 CONCETTI SWIFT UTILIZZATI:
 • UIActivityViewController: Share sheet nativo iOS
 • UIDocumentPickerViewController: File picker per import
 • JSONDecoder: Parsing JSON import
 • FileManager: Accesso file system
 • Merge logic: Integrazione dati senza duplicati
 • UIViewControllerRepresentable: Bridge SwiftUI-UIKit
 
 FUNZIONALITÀ:
 - Export file JSON con tutte le spese
 - Import file JSON da Files/iCloud
 - Merge intelligente (nessun duplicato)
 - Validazione formato JSON
 - Share sheet per export
 
 UTILIZZO:
 - Chiamato da menu settings
 - Export: condivide via AirDrop, Mail, etc.
 - Import: apre file picker
*/

import SwiftUI
import UniformTypeIdentifiers

/// Manager per gestire export/import dei dati
class ExportImportManager {
    
    // MARK: - Export
    
    /// Esporta i dati in un file JSON condivisibile
    /// - Returns: URL del file temporaneo da condividere
    static func exportData(_ expenses: [CategoriaSpesa]) throws -> URL {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        let data = try encoder.encode(expenses)
        
        // Crea file temporaneo per condivisione
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "MoneyTracker_Export_\(formattedDate()).json"
        let fileURL = tempDir.appendingPathComponent(fileName)
        
        try data.write(to: fileURL)
        
        print("✅ Export creato: \(fileURL.path)")
        return fileURL
    }
    
    /// Formatta data per nome file (YYYY-MM-DD)
    private static func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmm"
        return formatter.string(from: Date())
    }
    
    // MARK: - Import
    
    /// Importa spese da file JSON
    /// - Parameter fileURL: URL del file JSON da importare
    /// - Returns: Array di spese importate
    static func importData(from fileURL: URL) throws -> [CategoriaSpesa] {
        // Leggi il file
        let data = try Data(contentsOf: fileURL)
        
        // Decodifica JSON
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let expenses = try decoder.decode([CategoriaSpesa].self, from: data)
        
        print("✅ Import completato: \(expenses.count) spese")
        return expenses
    }
    
    /// Merge spese importate con quelle esistenti (evita duplicati)
    /// - Parameters:
    ///   - imported: Spese importate
    ///   - existing: Spese esistenti
    /// - Returns: Array unificato senza duplicati
    static func mergeExpenses(imported: [CategoriaSpesa], existing: [CategoriaSpesa]) -> [CategoriaSpesa] {
        var merged = existing
        var existingIDs = Set(existing.map { $0.id })
        
        // Aggiungi solo spese con ID non già presenti
        for expense in imported {
            if !existingIDs.contains(expense.id) {
                merged.append(expense)
                existingIDs.insert(expense.id)
            } else {
                print("⚠️ Spesa duplicata saltata: \(expense.nome) (ID: \(expense.id.uuidString.prefix(8)))")
            }
        }
        
        let addedCount = merged.count - existing.count
        print("✅ Merge completato: \(addedCount) nuove spese aggiunte")
        
        return merged
    }
    
    /// Valida che il file JSON sia nel formato corretto
    /// - Parameter fileURL: URL del file da validare
    /// - Returns: true se il formato è valido
    static func validateJSONFormat(fileURL: URL) -> Bool {
        do {
            let _ = try importData(from: fileURL)
            return true
        } catch {
            print("❌ Formato JSON non valido: \(error.localizedDescription)")
            return false
        }
    }
}

// MARK: - SwiftUI Wrappers

/// View per mostrare il share sheet (Export)
struct ActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil
    var onComplete: (() -> Void)? = nil
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
        
        controller.completionWithItemsHandler = { _, completed, _, _ in
            if completed {
                onComplete?()
            }
        }
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

/// View per mostrare il document picker (Import)
struct DocumentPicker: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    let onDocumentPicked: (URL) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(
            forOpeningContentTypes: [UTType.json],
            asCopy: true
        )
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker
        
        init(_ parent: DocumentPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            parent.onDocumentPicked(url)
            parent.isPresented = false
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.isPresented = false
        }
    }
}

// MARK: - Alert Helper

struct ImportExportAlert: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let isError: Bool
    
    static func success(_ message: String) -> ImportExportAlert {
        ImportExportAlert(title: "✅ Successo", message: message, isError: false)
    }
    
    static func error(_ message: String) -> ImportExportAlert {
        ImportExportAlert(title: "❌ Errore", message: message, isError: true)
    }
}
