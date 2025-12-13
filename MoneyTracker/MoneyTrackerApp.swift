//
//  MoneyTrackerApp.swift
//  MoneyTracker
//
//  Created by Mattia Di Donato on 15/08/25.
//

/*
 ENTRY POINT - MoneyTrackerApp (Punto di Ingresso dell'App)
 
 Questo è il file PRINCIPALE dell'intera app - il punto dove tutto inizia.
 È l'equivalente del main() nei linguaggi tradizionali, ma per SwiftUI.
 
 CONCETTI SWIFT/SWIFTUI UTILIZZATI:
 • @main: Attributo che indica a Swift che questo è il punto di ingresso dell'app
   - Solo UN file per progetto può avere @main
   - Swift cerca automaticamente questa struct al lancio dell'app
   - Sostituisce il vecchio AppDelegate pattern di UIKit
 
 • struct che implementa App: Il protocollo App è il cuore delle app SwiftUI
   - App è un protocollo che definisce il comportamento dell'applicazione
   - La struct deve implementare la proprietà `body` di tipo Scene
   - Gestisce il ciclo di vita dell'intera applicazione
 
 • WindowGroup: Tipo di Scene che crea una finestra per il contenuto
   - Su iOS: Crea l'unica finestra dell'app
   - Su macOS: Permette multiple finestre della stessa app
   - Su iPadOS: Supporta multitasking e finestre multiple
   - Gestisce automaticamente il lifecycle delle finestre
 
 • Scene: Rappresenta una parte dell'interfaccia utente dell'app
   - Le Scene sono containers per le Window
   - Diverse piattaforme supportano diversi tipi di Scene
   - WindowGroup è il tipo più comune di Scene
 
 CICLO DI VITA DELL'APP:
 1. iOS lancia l'app
 2. Swift trova @main e istanzia MoneyTrackerApp
 3. Il sistema chiama la proprietà body
 4. WindowGroup crea una finestra
 5. All'interno della finestra viene caricata ContentView()
 
 ARCHITETTURA:
 MoneyTrackerApp → WindowGroup → ContentView → NavigationView → HomeView
 
 CONFRONTO CON UIKIT:
 - UIKit: AppDelegate + SceneDelegate (codice complesso)
 - SwiftUI: Solo questo file (semplice e dichiarativo)
 
 STATO ATTUALE:
 - Implementazione minimal ma completa
 - Pronta per future estensioni (background tasks, deep links, etc.)
 - Compatibile con tutte le piattaforme Apple
 
 POSSIBILI ESTENSIONI FUTURE:
 - Aggiungere Settings scene
 - Implementare background app refresh
 - Gestire URL schemes per deep linking
 - Configurare environment values globali
 
 DESIGN PATTERN:
 - Application Entry Point Pattern: Singolo punto di ingresso controllato
 - Declarative UI: Descrizione di COSA mostrare, non COME mostrarlo
*/

import SwiftUI

@main
struct MoneyTrackerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()  // Vista radice dell'app
        }
        #if targetEnvironment(macCatalyst)
        .defaultSize(width: 1000, height: 700)  // Dimensione iniziale su Mac
        .commands {
            // Aggiungi comandi Mac-specific se servono in futuro
            CommandGroup(replacing: .help) {
                Button("MoneyTracker Help") {
                    // Apri help
                }
            }
        }
        #endif
    }
}
