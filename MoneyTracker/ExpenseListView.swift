//
//  ExpenseListView.swift
//  MoneyTracker
//
//  Created by Mattia Di Donato on 07/12/25.
//

import SwiftUI

/// Lista completa delle spese con filtri, ordinamento, ricerca e modifica.
struct ExpenseListView: View {
    // MARK: - Environment
    @EnvironmentObject var expenseManager: ExpenseManager
    @Environment(\.dismiss) var dismiss

    // MARK: - State
    @State private var filterOption: FilterOption = .all
    @State private var sortOption: SortOption = .dateNewest
    @State private var searchText = ""
    @State private var spesaDaModificare: CategoriaSpesa?

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

    /// Spese filtrate per periodo e ricerca testuale
    private var filteredExpenses: [CategoriaSpesa] {
        let calendar = Calendar.current
        let now = Date()

        let byPeriod: [CategoriaSpesa]
        switch filterOption {
        case .all:
            byPeriod = expenseManager.categorieSpese
        case .currentMonth:
            byPeriod = expenseManager.categorieSpese.filter {
                calendar.isDate($0.data, equalTo: now, toGranularity: .month)
            }
        case .currentYear:
            byPeriod = expenseManager.categorieSpese.filter {
                calendar.isDate($0.data, equalTo: now, toGranularity: .year)
            }
        }

        if searchText.isEmpty {
            return byPeriod
        }
        return byPeriod.filter {
            $0.nome.localizedCaseInsensitiveContains(searchText)
        }
    }

    /// Spese filtrate + ordinate
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

    /// Spese raggruppate per mese
    private var expensesByMonth: [(month: String, expenses: [CategoriaSpesa])] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        formatter.locale = Locale(identifier: "it_IT")

        let grouped = Dictionary(grouping: sortedExpenses) { spesa in
            calendar.dateComponents([.year, .month], from: spesa.data)
        }

        return grouped
            .compactMap { components, expenses -> (Date, String, [CategoriaSpesa])? in
                guard let date = calendar.date(from: components) else { return nil }
                return (date, formatter.string(from: date).capitalized, expenses)
            }
            .sorted { $0.0 > $1.0 }
            .map { ($0.1, $0.2) }
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

            // Lista spese raggruppate per mese
            if sortedExpenses.isEmpty {
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: searchText.isEmpty ? "tray" : "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)

                        Text(searchText.isEmpty ? "Nessuna spesa trovata" : "Nessun risultato per \"\(searchText)\"")
                            .font(.headline)
                            .foregroundColor(.primary)

                        Text(searchText.isEmpty ? "Prova a cambiare i filtri" : "Prova con un altro termine di ricerca")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                }
            } else {
                ForEach(expensesByMonth, id: \.month) { group in
                    Section {
                        ForEach(group.expenses) { spesa in
                            ExpenseRowFull(
                                spesa: spesa,
                                onDelete: {
                                    expenseManager.rimuoviSpesa(spesa)
                                }
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                spesaDaModificare = spesa
                            }
                        }
                    } header: {
                        HStack {
                            Text(group.month)
                            Spacer()
                            let sectionTotal = group.expenses.reduce(0) { $0 + $1.importo }
                            Text("€\(String(format: "%.2f", sectionTotal))")
                                .fontWeight(.medium)
                        }
                    }
                }
            }
        }
        .navigationTitle("Tutte le Spese")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
        .searchable(text: $searchText, prompt: "Cerca spesa per nome...")
        .sheet(item: $spesaDaModificare) { spesa in
            AddExpenseView(spesaDaModificare: spesa)
                .environmentObject(expenseManager)
        }
        .toolbar {
            #if os(iOS)
            ToolbarItem(placement: .navigationBarTrailing) {
                filterMenu
            }
            #else
            ToolbarItem(placement: .automatic) {
                filterMenu
            }
            #endif
        }
    }

    // MARK: - Filter Menu

    private var filterMenu: some View {
        Menu {
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
}

// MARK: - ExpenseRowFull

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
            RoundedRectangle(cornerRadius: 4)
                .fill(spesa.colore)
                .frame(width: 4, height: 50)

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
