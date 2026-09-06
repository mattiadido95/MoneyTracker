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

@MainActor
class ExpenseManager: ObservableObject {
    // MARK: - Published Properties
    
    @Published private(set) var totaleMensile: Double = 0
    @Published private(set) var totaleAnno: Double = 0
    @Published private(set) var prossimaScadenza = "Nessuna"
    @Published private(set) var numeroBolletteMese: Int = 0
    @Published private(set) var mediaMensile: Double = 0
    @Published private(set) var storageErrorMessage: String?
    @Published private(set) var storageNoticeMessage: String?
    @Published private(set) var canModifyData = false
    @Published private(set) var hasLoadedStorage = false

    @Published private(set) var categorieSpese: [CategoriaSpesa] = [] {
        didSet {
            calcolaTotali()
        }
    }

    private let persistenceManager: PersistenceManager
    private let persistenceEnabled: Bool
    
    // MARK: - Initialization
    
    /// Initializer standard (carica dati da persistenza)
    init(persistenceManager: PersistenceManager = .live) {
        self.persistenceManager = persistenceManager
        self.persistenceEnabled = true
        caricaDati()
        calcolaTotali()
    }
    
    /// Initializer per preview/testing (usa dati mock, NO auto-save)
    init(mockData: Bool) {
        self.persistenceManager = .live
        self.persistenceEnabled = false
        self.canModifyData = true
        self.hasLoadedStorage = true
        if mockData {
            caricaDatiMockPerPreview()
        }
        calcolaTotali()
    }
    
    // MARK: - Public Methods
    
    /// Aggiunge una nuova spesa alla lista
    @discardableResult
    func aggiungiSpesa(_ spesa: CategoriaSpesa) -> Bool {
        var updated = categorieSpese
        updated.append(spesa)
        return commit(updated)
    }

    /// Inserisce più spese con un solo salvataggio validato.
    @discardableResult
    func aggiungiSpese(_ spese: [CategoriaSpesa]) -> Bool {
        guard !spese.isEmpty else { return true }
        var updated = categorieSpese
        updated.append(contentsOf: spese)
        return commit(updated)
    }
    
    /// Rimuove una spesa dalla lista
    @discardableResult
    func rimuoviSpesa(_ spesa: CategoriaSpesa) -> Bool {
        let updated = categorieSpese.filter { $0.id != spesa.id }
        return commit(updated)
    }

    /// Aggiorna una spesa esistente (stesso ID)
    @discardableResult
    func aggiornaSpesa(_ spesa: CategoriaSpesa) -> Bool {
        guard let index = categorieSpese.firstIndex(where: { $0.id == spesa.id }) else {
            return false
        }
        var updated = categorieSpese
        updated[index] = spesa
        return commit(updated)
    }

    /// Cambia categoria a un insieme di spese in batch (un singolo didSet → un solo save)
    @discardableResult
    func cambiaCategoriaMultiple(ids: Set<UUID>, nuovaCategoria: String) -> Bool {
        guard !ids.isEmpty else { return true }
        let nuovoColore = CategoriaSpesa.colorForCategoria(nuovaCategoria)
        var updated = categorieSpese
        for i in updated.indices where ids.contains(updated[i].id) {
            let originale = updated[i]
            updated[i] = CategoriaSpesa(
                id: originale.id,
                nome: originale.nome,
                importo: originale.importo,
                colore: nuovoColore,
                data: originale.data,
                categoria: nuovaCategoria
            )
        }
        return commit(updated)
    }

    /// Rimuove spese agli indici specificati
    @discardableResult
    func rimuoviSpese(at offsets: IndexSet) -> Bool {
        var updated = categorieSpese
        updated.remove(atOffsets: offsets)
        return commit(updated)
    }

    /// Rimuove più spese per ID con un unico salvataggio transazionale.
    @discardableResult
    func rimuoviSpese(ids: Set<UUID>) -> Bool {
        guard !ids.isEmpty else { return true }
        let updated = categorieSpese.filter { !ids.contains($0.id) }
        return commit(updated)
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

    /// Persiste prima il nuovo stato e lo pubblica soltanto dopo il successo.
    /// In caso di errore conserva in memoria e su disco l'ultimo stato valido.
    @discardableResult
    private func commit(_ updatedExpenses: [CategoriaSpesa]) -> Bool {
        guard canModifyData else {
            storageErrorMessage = "Le modifiche sono bloccate perché lo storage non è stato caricato in modo sicuro. Riavvia l'app dopo aver verificato i file di backup."
            return false
        }

        guard persistenceEnabled else {
            categorieSpese = updatedExpenses
            return true
        }

        do {
            try persistenceManager.save(updatedExpenses)
            categorieSpese = updatedExpenses
            storageErrorMessage = nil
            return true
        } catch let error as PersistenceManager.PersistenceError {
            if case .validationFailed = error {
                storageErrorMessage = "Salvataggio annullato: \(error.localizedDescription) I dati correnti non sono stati modificati."
            } else {
                canModifyData = false
                storageErrorMessage = "Salvataggio annullato: \(error.localizedDescription) Le modifiche sono state bloccate per proteggere l'ultima copia valida."
            }
            return false
        } catch {
            canModifyData = false
            storageErrorMessage = "Salvataggio annullato: \(error.localizedDescription) Le modifiche sono state bloccate per proteggere l'ultima copia valida."
            return false
        }
    }

    /// Carica i dati dal file JSON
    private func caricaDati() {
        do {
            let result = try persistenceManager.load()
            categorieSpese = result.expenses
            storageNoticeMessage = result.userNotice
            canModifyData = true
            hasLoadedStorage = true
        } catch {
            // Non interpretare mai un errore come un archivio vuoto valido.
            categorieSpese = []
            canModifyData = false
            hasLoadedStorage = false
            storageErrorMessage = error.localizedDescription
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
                data: calendar.date(byAdding: .day, value: -2, to: now) ?? now,
                categoria: "Affitto"
            ),
            CategoriaSpesa(
                nome: "Bolletta Luce",
                importo: 89.50,
                colore: .yellow,
                data: calendar.date(byAdding: .day, value: -5, to: now) ?? now,
                categoria: "Utenze"
            ),
            CategoriaSpesa(
                nome: "Bolletta Gas",
                importo: 156.20,
                colore: .yellow,
                data: calendar.date(byAdding: .day, value: -10, to: now) ?? now,
                categoria: "Utenze"
            ),
            CategoriaSpesa(
                nome: "Internet Fibra",
                importo: 29.90,
                colore: .indigo,
                data: calendar.date(byAdding: .day, value: -3, to: now) ?? now,
                categoria: "Telecomunicazioni"
            )
        ]
        
    }

    // MARK: - Storage messages and diagnostics

    func dismissStorageError() {
        storageErrorMessage = nil
    }

    func dismissStorageNotice() {
        storageNoticeMessage = nil
    }

    /// Mostra informazioni sul file di persistenza
    func mostraInfoFile() {
        print(persistenceManager.fileInfo())
    }
    
    // MARK: - Export/Import Methods
    
    /// Esporta i dati correnti in un file JSON
    /// - Returns: URL del file temporaneo da condividere
    func exportData() throws -> URL {
        guard hasLoadedStorage else {
            throw ExpenseManagerError.storageNotLoaded
        }
        return try ExportImportManager.exportData(categorieSpese)
    }
    
    /// Importa e unisce dati da un file JSON
    /// - Parameter fileURL: URL del file JSON da importare
    /// - Returns: Numero di spese aggiunte
    func importData(from fileURL: URL) throws -> Int {
        let importedExpenses = try ExportImportManager.importData(from: fileURL)
        let countBefore = categorieSpese.count

        // Merge con dati esistenti (evita duplicati per ID)
        let mergedExpenses = ExportImportManager.mergeExpenses(
            imported: importedExpenses,
            existing: categorieSpese
        )

        guard commit(mergedExpenses) else {
            throw ExpenseManagerError.storageWriteFailed(
                storageErrorMessage ?? "Errore storage sconosciuto."
            )
        }

        let countAfter = mergedExpenses.count
        let addedCount = countAfter - countBefore

        print("📥 Import completato: \(addedCount) nuove spese aggiunte")
        return addedCount
    }
}

private enum ExpenseManagerError: LocalizedError {
    case storageWriteFailed(String)
    case storageNotLoaded

    var errorDescription: String? {
        switch self {
        case .storageWriteFailed(let message):
            return message
        case .storageNotLoaded:
            return "Lo storage non è stato caricato in modo sicuro; l'export è stato annullato per evitare di creare un archivio vuoto fuorviante."
        }
    }
}
