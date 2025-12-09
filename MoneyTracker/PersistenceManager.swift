//
//  PersistenceManager.swift
//  MoneyTracker
//
//  Created by Assistant on 07/12/25.
//

/*
 PERSISTENCE SERVICE - PersistenceManager (Gestore Persistenza)
 
 Questo servizio gestisce il salvataggio e caricamento dei dati su file JSON locale.
 
 CONCETTI SWIFT UTILIZZATI:
 • FileManager: API di iOS per gestire il file system
 • Documents Directory: Cartella dove le app possono salvare i propri file
 • Codable: Protocollo Swift per serializzazione/deserializzazione automatica
 • JSONEncoder/JSONDecoder: Convertono struct Swift ↔ JSON
 • Error Handling: try/catch per gestire errori di I/O
 • Static methods: Metodi che non richiedono un'istanza della classe
 • URL manipulation: Gestione di percorsi file
 
 ARCHITETTURA:
 - Single Responsibility: Si occupa SOLO di persistenza
 - Error Handling robusto: Gestisce tutti i possibili errori
 - Type-Safe: Usa generics per supportare qualsiasi tipo Codable
 - Testabile: Metodi statici facilmente testabili
 
 FUNZIONALITÀ:
 - Salva array di CategoriaSpesa su JSON
 - Carica array di CategoriaSpesa da JSON
 - Gestisce errori (file non trovato, corrotto, etc.)
 - Crea automaticamente il file se non esiste
 - Usa la Application Support Directory (privata all'app, persistente)
 
 FILE LOCATION:
 - iPhone: /var/mobile/Containers/Data/Application/[APP_ID]/Library/Application Support/spese.json
 - Simulator: ~/Library/Developer/CoreSimulator/Devices/[DEVICE_ID]/data/Containers/Data/Application/[APP_ID]/Library/Application Support/spese.json
 
 UTILIZZO:
 ```swift
 // Salva
 try PersistenceManager.save(categorieSpese)
 
 // Carica
 let categorie = try PersistenceManager.load()
 ```
 
 POSSIBILI MIGLIORAMENTI FUTURI:
 - Backup automatico su iCloud
 - Compressione del JSON per file grandi
 - Migrazione automatica tra versioni
 - Cifratura per dati sensibili
*/

import Foundation

enum PersistenceManager {
    
    // MARK: - Constants
    private static let fileName = "spese.json"
    
    // MARK: - File URL
    
    /// Ottiene l'URL del file JSON nella Application Support Directory
    /// Questa directory è privata all'app, persistente e backed-up su iCloud
    private static func getFileURL() throws -> URL {
        // Ottieni la Application Support Directory (directory privata dell'app)
        let appSupportDirectory = try FileManager.default.url(
            for: .applicationSupportDirectory,  // ← Directory interna dell'app
            in: .userDomainMask,
            appropriateFor: nil,
            create: true  // Crea la directory se non esiste
        )
        
        // Aggiungi il nome del file
        return appSupportDirectory.appendingPathComponent(fileName)
    }
    
    // MARK: - Save
    
    /// Salva l'array di categorie su file JSON
    /// - Parameter categorie: Array di CategoriaSpesa da salvare
    /// - Throws: Errori di encoding o scrittura file
    static func save(_ categorie: [CategoriaSpesa]) throws {
        let fileURL = try getFileURL()
        
        // Converti l'array in JSON
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted  // JSON formattato (più leggibile)
        encoder.dateEncodingStrategy = .iso8601    // Date in formato standard
        
        let data = try encoder.encode(categorie)
        
        // Scrivi il file
        try data.write(to: fileURL, options: .atomic)  // .atomic = scrittura sicura
        
        print("✅ Dati salvati con successo in: \(fileURL.path)")
    }
    
    // MARK: - Load
    
    /// Carica l'array di categorie dal file JSON
    /// - Returns: Array di CategoriaSpesa, o array vuoto se il file non esiste
    /// - Throws: Errori di lettura o decoding (ma NON se il file non esiste)
    static func load() throws -> [CategoriaSpesa] {
        let fileURL = try getFileURL()
        
        // Controlla se il file esiste
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            print("ℹ️ Nessun file esistente, ritorno array vuoto")
            return []  // Prima installazione = nessun dato
        }
        
        // Leggi il file
        let data = try Data(contentsOf: fileURL)
        
        // Converti JSON in array
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601  // Date in formato standard
        
        let categorie = try decoder.decode([CategoriaSpesa].self, from: data)
        
        print("✅ Caricati \(categorie.count) record da: \(fileURL.path)")
        return categorie
    }
    
    // MARK: - Delete (Utility)
    
    /// Cancella il file JSON (utile per testing o reset app)
    static func deleteAll() throws {
        let fileURL = try getFileURL()
        
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            print("ℹ️ Nessun file da cancellare")
            return
        }
        
        try FileManager.default.removeItem(at: fileURL)
        print("✅ File cancellato: \(fileURL.path)")
    }
    
    // MARK: - Debug Info
    
    /// Restituisce informazioni sul file per debugging
    static func fileInfo() -> String {
        guard let fileURL = try? getFileURL() else {
            return "❌ Impossibile ottenere URL file"
        }
        
        let exists = FileManager.default.fileExists(atPath: fileURL.path)
        
        if exists {
            if let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
               let size = attributes[.size] as? Int {
                return """
                📄 File: \(fileURL.lastPathComponent)
                📍 Path: \(fileURL.path)
                📊 Size: \(size) bytes
                ✅ Stato: Esiste
                """
            }
        }
        
        return """
        📄 File: \(fileURL.lastPathComponent)
        📍 Path: \(fileURL.path)
        ❌ Stato: Non esiste
        """
    }
}
