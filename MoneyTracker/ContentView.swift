/*
 ROOT VIEW - ContentView (Vista Radice dell'App)
 
 Questa è la vista RADICE dell'intera applicazione MoneyTracker - il punto di ingresso
 principale da cui parte tutta l'esperienza utente.
 
 CONCETTI SWIFT/SWIFTUI UTILIZZATI:
 • @StateObject: Property wrapper che CREA e POSSIEDE l'oggetto ExpenseManager
   - @StateObject vs @ObservedObject: StateObject lo crea, ObservedObject lo riceve
   - Garantisce che ExpenseManager viva per tutta la durata dell'app
   - SwiftUI distrugge e ricrea questo oggetto solo quando necessario
 • private: Il manager è privato, accessibile solo all'interno di ContentView
 • .environmentObject(): Inietta ExpenseManager nell'environment di tutte le view figlie
   - Tutte le view discendenti possono accedervi con @EnvironmentObject
   - Pattern di Dependency Injection di SwiftUI
 • NavigationView: Container per il sistema di navigazione iOS/macOS
   - Fornisce NavigationBar, titoli, pulsanti back automatici
   - Gestisce lo stack di navigazione per screen multiple
 
 ARCHITETTURA DELL'APP:
 ContentView è il "Root Container" che:
 1. Inizializza il sistema di gestione dati (ExpenseManager)
 2. Configura il sistema di navigazione (NavigationView)  
 3. Avvia la schermata principale (HomeView)
 4. Distribuisce i dati a tutta l'app tramite environment
 
 FLUSSO DATI (Data Flow):
 ContentView → [crea] → ExpenseManager → [inietta via environment] → HomeView → Componenti figli
 
 PATTERN ARCHITETTURALE:
 - MVVM (Model-View-ViewModel): ExpenseManager è il ViewModel
 - Unidirectional Data Flow: I dati scorrono in una direzione
 - Composition Root: Punto dove si assemblano tutte le dipendenze
 
 STATO ATTUALE:
 - Completamente funzionale come entry point
 - ExpenseManager inizializzato con dati mock per prototipazione
 - NavigationView pronta per future schermate di navigazione
 - Environment injection funzionante per tutti i componenti figli
 
 UTILIZZO NEL PROGETTO:
 - Utilizzata come prima view nell'AppDelegate o in @main App
 - Punto centrale di coordinamento per tutta l'applicazione
 - Proprietaria dell'unico ExpenseManager condiviso nell'app
 
 DESIGN PATTERN IMPLEMENTATI:
 - Singleton-like Behavior: Un solo ExpenseManager per tutta l'app
 - Inversion of Control: Le view figlie ricevono le dipendenze dall'esterno
 - Service Locator: Environment object come registro di servizi condivisi
*/

import SwiftUI

struct ContentView: View {
    // Stati principali dell'app - ExpenseManager è il ViewModel centrale
    // @StateObject lo CREA e lo POSSIEDE per tutta la durata dell'app
    @StateObject private var expenseManager = ExpenseManager()
    
    var body: some View {
        #if os(macOS)
        // Su macOS, usa NavigationStack con frame minimo per evitare compressione
        NavigationStack {
            HomeView()
                .environmentObject(expenseManager)
        }
        .frame(minWidth: 900, idealWidth: 1200, maxWidth: .infinity,
               minHeight: 700, idealHeight: 800, maxHeight: .infinity)
        #else
        // Su iOS, usa NavigationStack (o NavigationView per compatibilità con iOS 15)
        if #available(iOS 16.0, *) {
            NavigationStack {
                HomeView()
                    .environmentObject(expenseManager)
            }
        } else {
            NavigationView {
                HomeView()
                    .environmentObject(expenseManager)
            }
            .navigationViewStyle(.stack)
        }
        #endif
    }
}

// MARK: - SwiftUI Previews
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView_PreviewWrapper()
    }
}

/// Wrapper per preview con dati mock
private struct ContentView_PreviewWrapper: View {
    @StateObject private var expenseManager = ExpenseManager(mockData: true)
    
    var body: some View {
        #if os(macOS)
        NavigationStack {
            HomeView()
                .environmentObject(expenseManager)
        }
        .frame(minWidth: 900, idealWidth: 1200, maxWidth: .infinity,
               minHeight: 700, idealHeight: 800, maxHeight: .infinity)
        #else
        if #available(iOS 16.0, *) {
            NavigationStack {
                HomeView()
                    .environmentObject(expenseManager)
            }
        } else {
            NavigationView {
                HomeView()
                    .environmentObject(expenseManager)
            }
            .navigationViewStyle(.stack)
        }
        #endif
    }
}
