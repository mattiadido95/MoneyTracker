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
    @State private var showingAddExpense = false
    @State private var showingExportSheet = false
    @State private var showingImportPicker = false
    @State private var exportFileURL: URL?
    @State private var alertItem: ImportExportAlert?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                dashboardContent
                
                Spacer(minLength: 20)
            }
            .padding(.horizontal, 16)
            #if os(macOS)
            .padding(.vertical, 20)
            #endif
        }
        .navigationTitle("Dashboard Spese")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
        .background(Color.systemGroupedBackground)
        .sheet(isPresented: $showingAddExpense) {
            AddExpenseView()
                .environmentObject(expenseManager)
        }
        .sheet(isPresented: $showingExportSheet) {
            if let fileURL = exportFileURL {
                ActivityViewController(activityItems: [fileURL]) {
                    alertItem = .success("File esportato con successo!")
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    Text("Impossibile preparare il file per la condivisione.")
                        .font(.headline)
                }
                .padding()
            }
        }
        .sheet(isPresented: $showingImportPicker) {
            DocumentPicker(isPresented: $showingImportPicker, onFilePicked: handleImport)
        }
        .alert(item: $alertItem) { alert in
            Alert(
                title: Text(alert.title),
                message: Text(alert.message),
                dismissButton: .default(Text("OK"))
            )
        }
        .toolbar {
            #if os(iOS)
            ToolbarItem(placement: .navigationBarTrailing) {
                menuButton
            }
            #else
            ToolbarItem(placement: .automatic) {
                menuButton
            }
            #endif
        }
    }
    
    // MARK: - Dashboard Content
    
    @ViewBuilder
    private var dashboardContent: some View {
        // Header component
        HeaderCard(
            totaleMensile: expenseManager.totaleMensile,
            totaleAnno: expenseManager.totaleAnno
        )
        
        // Add expense button component
        AddExpenseButton {
            showingAddExpense = true
        }
        
        // Summary cards component
        SummaryCardsGrid(
            totaleAnno: expenseManager.totaleAnno,
            prossimaScadenza: expenseManager.prossimaScadenza,
            numeroBolletteMese: expenseManager.numeroBolletteMese,
            mediaMensile: expenseManager.mediaMensile
        )
        
        // Statistics button
        NavigationLink {
            StatisticsView()
                .environmentObject(expenseManager)
        } label: {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.title2)
                
                Text("Vedi Statistiche e Grafici")
                    .font(.headline)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            .foregroundColor(.white)
            .padding()
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [.green, .green.opacity(0.8)]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
            .shadow(color: .green.opacity(0.3), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        
        // Categories section component
        CategoriesSection(totaleMensile: expenseManager.totaleMensile)
    }
    
    // MARK: - Computed Views
    
    private var menuButton: some View {
        Menu {
            Section("Backup & Sincronizzazione") {
                Button(action: handleExport) {
                    Label("Esporta Dati", systemImage: "square.and.arrow.up")
                }
                
                Button(action: { showingImportPicker = true }) {
                    Label("Importa Dati", systemImage: "square.and.arrow.down")
                }
            }
            
            Section("Debug") {
                Button(action: {
                    expenseManager.mostraInfoFile()
                }) {
                    Label("Info File", systemImage: "info.circle")
                }
                
                Button(role: .destructive, action: {
                    expenseManager.resetDati()
                }) {
                    Label("Reset Dati", systemImage: "trash")
                }
            }
        } label: {
            Image(systemName: "ellipsis.circle")
        }
    }
    
    // MARK: - Export/Import Methods
    
    /// Gestisce l'export dei dati
    private func handleExport() {
        do {
            // Esporta i dati e ottieni l'URL del file temporaneo
            let fileURL = try expenseManager.exportData()
            
            // Salva l'URL e mostra lo share sheet
            exportFileURL = fileURL
            showingExportSheet = true
            
            print("✅ Export preparato, mostro share sheet")
        } catch {
            // Mostra errore
            alertItem = .error("Impossibile esportare i dati: \(error.localizedDescription)")
            print("❌ Errore export: \(error)")
        }
    }
    
    /// Gestisce l'import dei dati da un file
    /// - Parameter fileURL: URL del file JSON da importare
    private func handleImport(from fileURL: URL) {
        do {
            // Importa e unisci i dati
            let addedCount = try expenseManager.importData(from: fileURL)
            
            // Mostra risultato
            if addedCount > 0 {
                alertItem = .success("Import completato! \(addedCount) spese aggiunte.")
            } else {
                alertItem = .success("Import completato! Nessuna nuova spesa (tutte già presenti).")
            }
            
            print("✅ Import completato: \(addedCount) spese aggiunte")
        } catch {
            // Mostra errore
            alertItem = .error("Impossibile importare i dati: \(error.localizedDescription)")
            print("❌ Errore import: \(error)")
        }
    }
}


