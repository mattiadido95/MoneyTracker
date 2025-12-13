//
//  ExpenseListView.swift
//  MoneyTracker
//
//  Created by Assistant on 07/12/25.
//

/*
 VIEW - ExpenseListView (Lista Completa Spese)
 
 Questa schermata mostra la lista completa di tutte le spese con opzioni di filtro e ordinamento.
 
 CONCETTI SWIFT/SWIFTUI UTILIZZATI:
 • @EnvironmentObject: Riceve ExpenseManager condiviso
 • @State: Gestisce stato locale (filtri, ordinamento)
 • List: Container nativo per liste scrollabili
 • Section: Raggruppa elementi nella lista
 • Picker: Selettore nativo per filtri
 • @ViewBuilder: Costruisce view condizionali
 • Computed properties: Filtra e ordina i dati
 
 FUNZIONALITÀ:
 - Mostra tutte le spese in una lista
 - Filtro per mese (Tutti, Mese Corrente, Anno Corrente)
 - Ordinamento (Più Recenti, Più Vecchie, Importo Alto, Importo Basso)
 - Swipe-to-delete integrato
 - Empty state quando nessuna spesa match i filtri
 - Statistiche in header
 
 UX DESIGN:
 - Navigation title grande
 - Toolbar con filtri
 - Sezioni per mese se necessario
 - Pull-to-refresh (opzionale)
 
 UTILIZZO:
 - Navigazione push da HomeView
 - Pulsante "Vedi Tutto" in CategoriesSection
*/

import SwiftUI

struct ExpenseListView: View {
    // MARK: - Environment
    @EnvironmentObject var expenseManager: ExpenseManager
    @Environment(\.dismiss) var dismiss
    
    // MARK: - State
    @State private var filterOption: FilterOption = .all
    @State private var sortOption: SortOption = .dateNewest
    
    // MARK: - Enums
    
    enum FilterOption: String, CaseIterable {
        case all = "Tutte"
        case currentMonth = "Questo Mese"
        case currentYear = "Quest'Anno"
        
        var icon: String {
            switch self {
            case .all: return "list.bullet"
            case .currentMonth: return "calendar"
            case .currentYear: return "calendar.badge.clock"
            }
        }
    }
    
    enum SortOption: String, CaseIterable {
        case dateNewest = "Più Recenti"
        case dateOldest = "Più Vecchie"
        case amountHigh = "Importo ↓"
        case amountLow = "Importo ↑"
        
        var icon: String {
            switch self {
            case .dateNewest: return "arrow.down"
            case .dateOldest: return "arrow.up"
            case .amountHigh: return "arrow.down.circle"
            case .amountLow: return "arrow.up.circle"
            }
        }
    }
    
    // MARK: - Computed Properties
    
    /// Spese filtrate in base all'opzione selezionata
    private var filteredExpenses: [CategoriaSpesa] {
        let calendar = Calendar.current
        let now = Date()
        
        switch filterOption {
        case .all:
            return expenseManager.categorieSpese
            
        case .currentMonth:
            return expenseManager.categorieSpese.filter { spesa in
                calendar.isDate(spesa.data, equalTo: now, toGranularity: .month)
            }
            
        case .currentYear:
            return expenseManager.categorieSpese.filter { spesa in
                calendar.isDate(spesa.data, equalTo: now, toGranularity: .year)
            }
        }
    }
    
    /// Spese filtrate e ordinate
    private var sortedExpenses: [CategoriaSpesa] {
        switch sortOption {
        case .dateNewest:
            return filteredExpenses.sorted { $0.data > $1.data }
            
        case .dateOldest:
            return filteredExpenses.sorted { $0.data < $1.data }
            
        case .amountHigh:
            return filteredExpenses.sorted { $0.importo > $1.importo }
            
        case .amountLow:
            return filteredExpenses.sorted { $0.importo < $1.importo }
        }
    }
    
    /// Totale delle spese filtrate
    private var totalFiltered: Double {
        filteredExpenses.reduce(0) { $0 + $1.importo }
    }
    
    // MARK: - Body
    
    var body: some View {
        List {
            // Header con statistiche
            Section {
                VStack(spacing: 8) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Totale Visualizzato")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("€\(String(format: "%.2f", totalFiltered))")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Numero Spese")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(sortedExpenses.count)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            
            // Lista spese
            Section {
                if sortedExpenses.isEmpty {
                    // Empty state
                    VStack(spacing: 12) {
                        Image(systemName: "tray")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        
                        Text("Nessuna spesa trovata")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("Prova a cambiare i filtri")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else {
                    ForEach(sortedExpenses) { spesa in
                        ExpenseRowFull(
                            spesa: spesa,
                            onDelete: {
                                expenseManager.rimuoviSpesa(spesa)
                            }
                        )
                    }
                    #if os(iOS)
                    .onDelete { indexSet in
                        deleteExpenses(at: indexSet)
                    }
                    #endif
                }
            }
        }
        .navigationTitle("Tutte le Spese")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
        .toolbar {
            #if os(iOS)
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    // Sezione Filtri
                    Section("Filtra per") {
                        ForEach(FilterOption.allCases, id: \.self) { option in
                            Button(action: { filterOption = option }) {
                                Label(
                                    option.rawValue,
                                    systemImage: option == filterOption ? "checkmark" : option.icon
                                )
                            }
                        }
                    }
                    
                    // Sezione Ordinamento
                    Section("Ordina per") {
                        ForEach(SortOption.allCases, id: \.self) { option in
                            Button(action: { sortOption = option }) {
                                Label(
                                    option.rawValue,
                                    systemImage: option == sortOption ? "checkmark" : option.icon
                                )
                            }
                        }
                    }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                }
            }
            #else
            ToolbarItem(placement: .automatic) {
                Menu {
                    // Sezione Filtri
                    Section("Filtra per") {
                        ForEach(FilterOption.allCases, id: \.self) { option in
                            Button(action: { filterOption = option }) {
                                Label(
                                    option.rawValue,
                                    systemImage: option == filterOption ? "checkmark" : option.icon
                                )
                            }
                        }
                    }
                    
                    // Sezione Ordinamento
                    Section("Ordina per") {
                        ForEach(SortOption.allCases, id: \.self) { option in
                            Button(action: { sortOption = option }) {
                                Label(
                                    option.rawValue,
                                    systemImage: option == sortOption ? "checkmark" : option.icon
                                )
                            }
                        }
                    }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                }
            }
            #endif
        }
    }
    
    // MARK: - Methods
    
    private func deleteExpenses(at offsets: IndexSet) {
        // Ottieni gli ID delle spese da eliminare
        let expensesToDelete = offsets.map { sortedExpenses[$0] }
        
        // Elimina dall'array principale
        for expense in expensesToDelete {
            expenseManager.rimuoviSpesa(expense)
        }
    }
}

// MARK: - ExpenseRowFull (Riga Dettagliata)

struct ExpenseRowFull: View {
    let spesa: CategoriaSpesa
    var onDelete: (() -> Void)? = nil
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "it_IT")
        return formatter.string(from: spesa.data)
    }
    
    private var relativeDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        formatter.locale = Locale(identifier: "it_IT")
        return formatter.localizedString(for: spesa.data, relativeTo: Date())
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Indicatore colorato
            RoundedRectangle(cornerRadius: 4)
                .fill(spesa.colore)
                .frame(width: 4, height: 50)
            
            // Info spesa
            VStack(alignment: .leading, spacing: 4) {
                Text(spesa.nome)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption2)
                    Text(formattedDate)
                        .font(.subheadline)
                    
                    Text("•")
                        .font(.caption2)
                    
                    Text(relativeDate)
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Importo
            VStack(alignment: .trailing, spacing: 2) {
                Text("€\(String(format: "%.2f", spesa.importo))")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(spesa.colore)
                
                Text("ID: \(spesa.id.uuidString.prefix(8))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            #if os(macOS)
            // Pulsante delete per macOS
            if let onDelete = onDelete {
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
                .help("Elimina spesa")
            }
            #endif
        }
        .padding(.vertical, 4)
        #if os(macOS)
        .contextMenu {
            if let onDelete = onDelete {
                Button(role: .destructive, action: onDelete) {
                    Label("Elimina", systemImage: "trash")
                }
            }
        }
        #endif
    }
}

// MARK: - Preview
struct ExpenseListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ExpenseListView()
                .environmentObject(ExpenseManager(mockData: true))
        }
    }
}
