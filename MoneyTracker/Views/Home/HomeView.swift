//
//  HomeView.swift
//  MoneyTracker
//
//  Created by Mattia Di Donato on 31/08/25.
//

/*
 VIEW PRINCIPALE - HomeView (Schermata Dashboard)
 
 Questa è la schermata principale dell'app - la dashboard che orchestrea tutti i componenti
 per creare l'esperienza utente completa della visualizzazione spese.
 
 CONCETTI SWIFT/SWIFTUI UTILIZZATI:
 • @EnvironmentObject: Riceve ExpenseManager condiviso da ContentView
 • ScrollView: Container scrollabile per contenuti che superano lo schermo
 • VStack con spacing: Stack verticale con spaziatura uniforme tra elementi
 • NavigationTitle: Titolo della navigation bar
 • NavigationBarTitleDisplayMode: .large per titolo grande stile iOS
 • Background colors: Color(.systemGroupedBackground) per look nativo
 • Padding horizontal: Margini laterali per non toccare i bordi
 • Spacer(minLength:): Spaziatura minima garantita in fondo
 • Trailing closure syntax: { } per le azioni dei pulsanti
 
 ARCHITETTURA COMPONENTI:
 La HomeView è un "Container View" che combina questi componenti:
 1. HeaderCard - Hero section con benvenuto e totale mensile
 2. AddExpenseButton - Call-to-action principale per aggiungere spese  
 3. SummaryCardsGrid - Griglia 2x2 con metriche chiave
 4. CategoriesSection - Lista delle categorie di spesa con dettagli
 
 FLUSSO DATI (Data Flow):
 - ExpenseManager → HomeView → Tutti i componenti figli
 - Ogni componente riceve solo i dati di cui ha bisogno
 - Nessun componente figlio modifica direttamente i dati (unidirezionale)
 
 UX DESIGN PATTERNS:
 - Dashboard Pattern: Panoramica completa in una sola schermata
 - Card-Based Layout: Informazioni organizzate in sezioni distinte
 - Scannable Content: Layout verticale per scorrimento naturale
 - Action-Oriented: Pulsante prominente per l'azione principale
 
 STATO ATTUALE:
 - Layout e design completamente implementati
 - Tutti i componenti renderizzano dati da ExpenseManager
 - Navigazione di aggiunta spese non implementata (print placeholder)
 - "Vedi Tutto" categorie non implementato
 
 UTILIZZO NEL PROGETTO:
 - Utilizzata da ContentView come schermata principale
 - Punto di ingresso per tutte le funzionalità dell'app
 - Hub che collega tutti i componenti UI principali
 
 DESIGN PATTERN:
 - Container-Presenter Pattern: Organizza e presenta i dati
 - Composition Root: Punto dove tutti i componenti si uniscono
 - Unidirectional Data Flow: I dati scendono, le azioni salgono
*/

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var expenseManager: ExpenseManager
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                
                // Header component
                HeaderCard(
                    totaleMensile: expenseManager.totaleMensile,
                    totaleAnno: expenseManager.totaleAnno
                )
                
                // Add expense button component
                AddExpenseButton {
                    // Navigazione alla schermata di aggiunta
                    print("Navigate to add expense")
                }
                
                // Summary cards component
                SummaryCardsGrid(
                    totaleAnno: expenseManager.totaleAnno,
                    prossimaScadenza: expenseManager.prossimaScadenza,
                    numeroBolletteMese: expenseManager.numeroBolletteMese,
                    mediaMensile: expenseManager.mediaMensile
                )
                
                // Categories section component
                CategoriesSection(
                    categorie: expenseManager.categorieSpese,
                    totaleMensile: expenseManager.totaleMensile
                )
                
                Spacer(minLength: 20)
            }
            .padding(.horizontal, 16)
        }
        .navigationTitle("Dashboard Spese")
        .navigationBarTitleDisplayMode(.large)
        .background(Color(.systemGroupedBackground))
    }
}
