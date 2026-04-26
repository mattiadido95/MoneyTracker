//
//  ExpenseManager.swift
//  MoneyTracker
//
//  Created by Mattia Di Donato on 31/08/25.
//

/*
 VIEWMODEL - ExpenseManager (Gestore delle Spese)
 
 Questo è il CUORE LOGICO dell'app - gestisce tutti i dati e le operazioni sulle spese.
 
 CONCETTI SWIFT UTILIZZATI:
 • class: Tipo di riferimento (reference type)
 • ObservableObject: Protocollo che permette alla classe di notificare le View dei cambiamenti
 • @Published: Property wrapper che notifica automaticamente le View quando il valore cambia
 • Combine framework: Sistema reattivo di Apple per gestire eventi asincroni
 • didSet: Property observer che viene chiamato dopo ogni modifica
 • init(): Costruttore chiamato alla creazione dell'oggetto
 • Calendar: API per operazioni su date (filtraggio per mese/anno)
 
 FUNZIONALITÀ PRINCIPALI:
 - Memorizza e gestisce tutte le spese per categoria
 - Calcola automaticamente i totali (mensile, annuale, media)
 - Salva e carica automaticamente i dati da file JSON
 - Fornisce metodi per aggiungere/rimuovere spese
 - Notifica automaticamente le View quando i dati cambiano
 
 STATO ATTUALE:
 - ✅ Persistenza JSON implementata
 - ✅ Calcoli automatici completi
 - ✅ Auto-save dopo ogni modifica
 - ✅ Caricamento dati all'avvio
 
 UTILIZZO NEL PROGETTO:
 - ContentView lo crea come @StateObject
 - HomeView lo riceve come @EnvironmentObject
 - Tutti i componenti UI leggono i suoi dati per visualizzarli
*/

import SwiftUI
import Combine

class ExpenseManager: ObservableObject {
    // MARK: - Published Properties
    
    @Published var totaleMensile: Double = 0
    @Published var totaleAnno: Double = 0
    @Published var prossimaScadenza = "Nessuna"
    @Published var numeroBolletteMese: Int = 0
    @Published var mediaMensile: Double = 0
    
    // Flag per disabilitare auto-save (utile per preview/testing)
    private var autoSaveEnabled: Bool = true
    
    @Published var categorieSpese: [CategoriaSpesa] = [] {
        didSet {
            // Auto-save: salva automaticamente ogni volta che l'array cambia
            if autoSaveEnabled {
                salvaDati()
            }
            calcolaTotali()
        }
    }
    
    // MARK: - Initialization
    
    /// Initializer standard (carica dati da persistenza)
    init() {
        print("🔵 ExpenseManager init() - START")
        // Disabilita auto-save durante inizializzazione
        self.autoSaveEnabled = false
        print("🔵 Auto-save disabilitato temporaneamente")
        
        caricaDati()
        print("🔵 Dati caricati")
        
        calcolaTotali()
        print("🔵 Totali calcolati")
        
        // Riabilita auto-save dopo inizializzazione completa
        self.autoSaveEnabled = true
        print("🔵 Auto-save riabilitato")
        print("🔵 ExpenseManager init() - COMPLETE")
    }
    
    /// Initializer per preview/testing (usa dati mock, NO auto-save)
    init(mockData: Bool) {
        print("🟣 ExpenseManager init(mockData: \(mockData)) - START")
        self.autoSaveEnabled = false  // Disabilita auto-save per preview
        if mockData {
            caricaDatiMockPerPreview()
        }
        calcolaTotali()
        print("🟣 ExpenseManager init(mockData:) - COMPLETE")
    }
    
    // MARK: - Public Methods
    
    /// Aggiunge una nuova spesa alla lista
    func aggiungiSpesa(_ spesa: CategoriaSpesa) {
        categorieSpese.append(spesa)
        // didSet verrà chiamato automaticamente → salva + ricalcola
    }
    
    /// Rimuove una spesa dalla lista
    func rimuoviSpesa(_ spesa: CategoriaSpesa) {
        categorieSpese.removeAll { $0.id == spesa.id }
        // didSet verrà chiamato automaticamente
    }
    
    /// Rimuove spese agli indici specificati
    func rimuoviSpese(at offsets: IndexSet) {
        categorieSpese.remove(atOffsets: offsets)
    }
    
    // MARK: - Private Methods - Calculations
    
    /// Calcola tutti i totali e le statistiche
    private func calcolaTotali() {
        let calendar = Calendar.current
        let now = Date()
        
        // Filtra spese del mese corrente
        let speseMeseCorrente = categorieSpese.filter { spesa in
            calendar.isDate(spesa.data, equalTo: now, toGranularity: .month)
        }
        
        // Filtra spese dell'anno corrente
        let speseAnnoCorrente = categorieSpese.filter { spesa in
            calendar.isDate(spesa.data, equalTo: now, toGranularity: .year)
        }
        
        // Totale mensile
        totaleMensile = speseMeseCorrente.reduce(0) { $0 + $1.importo }
        
        // Totale annuale
        totaleAnno = speseAnnoCorrente.reduce(0) { $0 + $1.importo }
        
        // Numero bollette del mese
        numeroBolletteMese = speseMeseCorrente.count
        
        // Media mensile (totale anno / 12)
        mediaMensile = totaleAnno / 12.0
        
        // Ultima spesa registrata (la piu recente come riferimento)
        if let prossimaSpesa = categorieSpese.sorted(by: { $0.data > $1.data }).first {
            let formatter = DateFormatter()
            formatter.dateFormat = "dd MMM"
            formatter.locale = Locale(identifier: "it_IT")
            prossimaScadenza = "\(prossimaSpesa.nome) - \(formatter.string(from: prossimaSpesa.data))"
        } else {
            prossimaScadenza = "Nessuna"
        }
    }
    
    // MARK: - Private Methods - Persistence
    
    /// Salva i dati su file JSON
    private func salvaDati() {
        do {
            try PersistenceManager.save(categorieSpese)
            print("💾 Dati salvati automaticamente")
        } catch {
            print("❌ Errore nel salvataggio: \(error.localizedDescription)")
        }
    }
    
    /// Carica i dati dal file JSON
    private func caricaDati() {
        do {
            let categorie = try PersistenceManager.load()
            
            // Carica i dati salvati (anche se vuoto)
            categorieSpese = categorie
            
            if categorie.isEmpty {
                print("ℹ️ Nessuna spesa presente. Inizia aggiungendone una!")
            } else {
                print("📂 Caricati \(categorie.count) record")
            }
        } catch {
            print("❌ Errore nel caricamento: \(error.localizedDescription)")
            // Anche in caso di errore, inizia con array vuoto
            categorieSpese = []
        }
    }
    
    /// Carica dati mock per preview/testing (NON salva su disco)
    private func caricaDatiMockPerPreview() {
        let calendar = Calendar.current
        let now = Date()
        
        // Crea spese di esempio senza salvare (autoSaveEnabled è false)
        categorieSpese = [
            CategoriaSpesa(
                nome: "Affitto",
                importo: 800.00,
                colore: .purple,
                data: calendar.date(byAdding: .day, value: -2, to: now) ?? now
            ),
            CategoriaSpesa(
                nome: "Luce",
                importo: 89.50,
                colore: .yellow,
                data: calendar.date(byAdding: .day, value: -5, to: now) ?? now
            ),
            CategoriaSpesa(
                nome: "Gas",
                importo: 156.20,
                colore: .blue,
                data: calendar.date(byAdding: .day, value: -10, to: now) ?? now
            ),
            CategoriaSpesa(
                nome: "Internet",
                importo: 29.90,
                colore: .cyan,
                data: calendar.date(byAdding: .day, value: -3, to: now) ?? now
            )
        ]
        
        print("🎨 Caricati dati mock per preview (auto-save disabilitato)")
    }
    
    // MARK: - Debug Methods
    
    /// Resetta tutti i dati (utile per testing)
    func resetDati() {
        do {
            try PersistenceManager.deleteAll()
            categorieSpese = []
            print("🗑️ Tutti i dati sono stati resettati")
        } catch {
            print("❌ Errore nella cancellazione: \(error.localizedDescription)")
        }
    }
    
    /// Mostra informazioni sul file di persistenza
    func mostraInfoFile() {
        print(PersistenceManager.fileInfo())
    }
    
    // MARK: - Export/Import Methods
    
    /// Esporta i dati correnti in un file JSON
    /// - Returns: URL del file temporaneo da condividere
    func exportData() throws -> URL {
        return try ExportImportManager.exportData(categorieSpese)
    }
    
    /// Importa e unisce dati da un file JSON
    /// - Parameter fileURL: URL del file JSON da importare
    /// - Returns: Numero di spese aggiunte
    func importData(from fileURL: URL) throws -> Int {
        let importedExpenses = try ExportImportManager.importData(from: fileURL)
        let countBefore = categorieSpese.count
        
        // Merge con dati esistenti (evita duplicati per ID)
        categorieSpese = ExportImportManager.mergeExpenses(
            imported: importedExpenses,
            existing: categorieSpese
        )
        
        let countAfter = categorieSpese.count
        let addedCount = countAfter - countBefore
        
        print("📥 Import completato: \(addedCount) nuove spese aggiunte")
        return addedCount
    }
}
