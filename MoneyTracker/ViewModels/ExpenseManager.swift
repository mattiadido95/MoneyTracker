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
 • class: Tipo di riferimento (reference type) - quando assegni una classe a un'altra 
   variabile, entrambe puntano allo stesso oggetto in memoria
 • ObservableObject: Protocollo che permette alla classe di notificare le View dei cambiamenti
 • @Published: Property wrapper che notifica automaticamente le View quando il valore cambia
 • Combine framework: Sistema reattivo di Apple per gestire eventi asincroni
 • Array: Collezione ordinata di elementi dello stesso tipo
 • func: Definisce metodi (funzioni all'interno di una classe)
 • private: Visibilità limitata solo a questa classe
 
 FUNZIONALITÀ PRINCIPALI:
 - Memorizza e gestisce tutte le spese per categoria
 - Calcola automaticamente i totali (mensile, annuale, media)
 - Tiene traccia delle scadenze e statistiche
 - Fornisce metodi per aggiungere nuove spese
 - Notifica automaticamente le View quando i dati cambiano
 
 STATO ATTUALE:
 - Utilizza dati MOCK (finti) per il prototipo
 - La funzione calcolaTotali() è incompleta
 - Manca la persistenza (salvataggio su database)
 
 UTILIZZO NEL PROGETTO:
 - ContentView lo crea come @StateObject
 - HomeView lo riceve come @EnvironmentObject
 - Tutti i componenti UI leggono i suoi dati per visualizzarli
*/

import SwiftUI
import Combine

class ExpenseManager: ObservableObject {
    @Published var totaleMensile: Double = 1250.50
    @Published var totaleAnno: Double = 12890.75
    @Published var prossimaScadenza = "Luce - 15 Gen"
    @Published var numeroBolletteMese: Int = 8
    @Published var mediaMensile: Double = 1074.23
    
    @Published var categorieSpese = [
        CategoriaSpesa(nome: "Luce", importo: 89.50, colore: Color.yellow),
        CategoriaSpesa(nome: "Gas", importo: 156.20, colore: Color.blue),
        CategoriaSpesa(nome: "Acqua", importo: 45.80, colore: Color.cyan),
        CategoriaSpesa(nome: "Internet", importo: 29.90, colore: Color.purple),
        CategoriaSpesa(nome: "Tari", importo: 400.90, colore: Color.red)
    ]
    
    func aggiungiSpesa(_ spesa: CategoriaSpesa) {
        // Logica per aggiungere una nuova spesa
        categorieSpese.append(spesa)
        calcolaTotali()
    }
    
    private func calcolaTotali() {
        totaleMensile = categorieSpese.reduce(0) { $0 + $1.importo }
        // Altri calcoli...
    }
}
