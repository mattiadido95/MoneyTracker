//
//  ExportImportManager.swift
//  MoneyTracker
//
//  Created by Assistant on 13/12/25.
//

/*
 EXPORT/IMPORT SERVICE - ExportImportManager (Gestore Backup e Sincronizzazione)
 
 Questo servizio gestisce l'export e l'import dei dati per backup e sincronizzazione.
 
 CONCETTI SWIFT UTILIZZATI:
 • FileManager: Gestione file system iOS
 • Temporary Directory: Cartella temporanea per file da condividere
 • JSONEncoder/JSONDecoder: Serializzazione/Deserializzazione
 • Set operations: Operazioni su insiemi per merge intelligente
 • Error Handling: Gestione robusta degli errori
 • Static methods: Metodi di utilità senza stato
 
 FUNZIONALITÀ:
 - Export: Crea un file JSON condivisibile nella directory temporanea
 - Import: Legge un file JSON e restituisce le spese
 - Merge: Unisce dati importati con quelli esistenti (evita duplicati)
 
 STRATEGIA DI MERGE:
 - Usa gli ID delle spese per identificare duplicati
 - Le spese con ID già presenti vengono IGNORATE (priorità ai dati locali)
 - Solo le spese nuove vengono aggiunte
 - Preserva l'ordine: prima i dati esistenti, poi i nuovi
 
 FORMATO FILE:
 - File JSON con array di CategoriaSpesa
 - Date in formato ISO8601
 - Pretty-printed per leggibilità umana
 - Estensione: .json
 
 UTILIZZO:
 ```swift
 // Export
 let fileURL = try ExportImportManager.exportData(categorieSpese)
 // Condividi fileURL con UIActivityViewController
 
 // Import
 let importedExpenses = try ExportImportManager.importData(from: fileURL)
 let mergedExpenses = ExportImportManager.mergeExpenses(imported: importedExpenses, existing: categorieSpese)
 ```
 
 SICUREZZA:
 - I file temporanei vengono automaticamente eliminati da iOS
 - Nessun dato sensibile viene esposto se non autorizzato dall'utente
 - L'utente controlla sempre dove vanno i file (share sheet / file picker)
*/

import Foundation

enum ExportImportManager {
    
    // MARK: - Export
    
    /// Esporta le spese in un file JSON pronto per essere condiviso
    /// - Parameters:
    ///   - expenses: Array di spese da esportare
    ///   - persistent: Se true, salva in Documents (permanente), altrimenti in temp
    /// - Returns: URL del file
    /// - Throws: Errori di encoding o scrittura file
    static func exportData(_ expenses: [CategoriaSpesa], persistent: Bool = false) throws -> URL {
        // Crea un nome file con timestamp
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HHmmss"
        let timestamp = dateFormatter.string(from: Date())
        let fileName = "MoneyTracker_Export_\(timestamp).json"
        
        // Scegli la directory
        let directory: URL
        if persistent {
            // Documents = permanente, backup su iCloud
            directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        } else {
            // Temporary = auto-cleanup da iOS
            directory = FileManager.default.temporaryDirectory
        }
        let fileURL = directory.appendingPathComponent(fileName)
        
        // Configura l'encoder
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]  // JSON leggibile
        encoder.dateEncodingStrategy = .iso8601  // Date standard
        
        // Converti in JSON
        let data = try encoder.encode(expenses)
        
        // Scrivi il file
        try data.write(to: fileURL, options: .atomic)
        
        print("📤 Export completato: \(fileName)")
        print("📍 Path: \(fileURL.path)")
        print("📍 Directory: \(persistent ? "Documents (permanente)" : "Temp (auto-cleanup)")")
        print("📊 Spese esportate: \(expenses.count)")
        
        return fileURL
    }
    
    // MARK: - Import
    
    /// Importa spese da un file JSON
    /// - Parameter fileURL: URL del file JSON da importare
    /// - Returns: Array di spese importate
    /// - Throws: Errori di lettura o decoding
    static func importData(from fileURL: URL) throws -> [CategoriaSpesa] {
        // Permetti l'accesso al file (necessario per file picker)
        let accessing = fileURL.startAccessingSecurityScopedResource()
        defer {
            if accessing {
                fileURL.stopAccessingSecurityScopedResource()
            }
        }
        
        // Leggi il file
        let data = try Data(contentsOf: fileURL)
        
        // Configura il decoder
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        // Decodifica le spese
        let expenses = try decoder.decode([CategoriaSpesa].self, from: data)
        
        print("📥 Import completato: \(fileURL.lastPathComponent)")
        print("📊 Spese importate: \(expenses.count)")
        
        return expenses
    }
    
    // MARK: - Merge Strategy
    
    /// Unisce le spese importate con quelle esistenti, evitando duplicati
    /// - Parameters:
    ///   - imported: Spese importate dal file
    ///   - existing: Spese già presenti nel database
    /// - Returns: Array unificato senza duplicati
    static func mergeExpenses(
        imported: [CategoriaSpesa],
        existing: [CategoriaSpesa]
    ) -> [CategoriaSpesa] {
        // Crea un Set con gli ID delle spese esistenti
        let existingIDs = Set(existing.map { $0.id })
        
        // Filtra le spese importate: prendi solo quelle con ID nuovi
        let newExpenses = imported.filter { !existingIDs.contains($0.id) }
        
        print("🔀 Merge completato:")
        print("   - Spese esistenti: \(existing.count)")
        print("   - Spese importate: \(imported.count)")
        print("   - Nuove spese aggiunte: \(newExpenses.count)")
        print("   - Duplicati ignorati: \(imported.count - newExpenses.count)")
        
        // Restituisci: prima le esistenti, poi le nuove
        return existing + newExpenses
    }
    
    // MARK: - Validation
    
    /// Valida che un file sia un JSON valido di spese
    /// - Parameter fileURL: URL del file da validare
    /// - Returns: true se il file è valido, false altrimenti
    static func validateFile(_ fileURL: URL) -> Bool {
        do {
            _ = try importData(from: fileURL)
            return true
        } catch {
            print("❌ Validazione fallita: \(error.localizedDescription)")
            return false
        }
    }
}
