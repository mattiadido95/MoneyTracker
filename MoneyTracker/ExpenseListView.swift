//
//  ExpenseListView.swift
//  MoneyTracker
//

import SwiftUI

/// Lista completa delle spese con filtri, ordinamento, ricerca e modifica.
struct ExpenseListView: View {

    // MARK: - Environment
    @EnvironmentObject var expenseManager: ExpenseManager

    // MARK: - State
    @State private var filterPeriod: PeriodFilter = .all
    @State private var filterCategoria: String = "Tutte"
    @State private var sortOption: SortOption = .dateNewest
    @State private var searchText: String = ""
    @State private var spesaDaModificare: CategoriaSpesa?

    // MARK: - Enums

    enum PeriodFilter: String, CaseIterable {
        case all          = "Tutte"
        case currentMonth = "Questo Mese"
        case currentYear  = "Quest'Anno"
    }

    enum SortOption: String, CaseIterable {
        case dateNewest = "Più Recenti"
        case dateOldest = "Più Vecchie"
        case amountHigh = "Importo ↓"
        case amountLow  = "Importo ↑"
    }

    // MARK: - Computed Properties

    /// Categorie presenti nei dati (per il picker filtro)
    private var categorieDisponibili: [String] {
        let cats = Set(expenseManager.categorieSpese.map { $0.categoria })
        return ["Tutte"] + cats.sorted()
    }

    private var filteredExpenses: [CategoriaSpesa] {
        let calendar = Calendar.current
        let now = Date()

        var result = expenseManager.categorieSpese

        // Filtro periodo
        switch filterPeriod {
        case .currentMonth:
            result = result.filter { calendar.isDate($0.data, equalTo: now, toGranularity: .month) }
        case .currentYear:
            result = result.filter { calendar.isDate($0.data, equalTo: now, toGranularity: .year) }
        case .all:
            break
        }

        // Filtro categoria
        if filterCategoria != "Tutte" {
            result = result.filter { $0.categoria == filterCategoria }
        }

        // Ricerca testo
        if !searchText.isEmpty {
            result = result.filter {
                $0.nome.localizedCaseInsensitiveContains(searchText) ||
                $0.categoria.localizedCaseInsensitiveContains(searchText)
            }
        }

        // Ordinamento
        switch sortOption {
        case .dateNewest: return result.sorted { $0.data > $1.data }
        case .dateOldest: return result.sorted { $0.data < $1.data }
        case .amountHigh: return result.sorted { $0.importo > $1.importo }
        case .amountLow:  return result.sorted { $0.importo < $1.importo }
        }
    }

    private var totalFiltered: Double {
        filteredExpenses.reduce(0) { $0 + $1.importo }
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            filterBar
            list
        }
        .navigationTitle("Tutte le Spese")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, prompt: "Cerca per nome o categoria")
        #endif
        .toolbar { toolbarContent }
        .sheet(item: $spesaDaModificare) { spesa in
            AddExpenseView(spesaDaModificare: spesa)
                .environmentObject(expenseManager)
        }
    }

    // MARK: - Filter Bar

    private var filterBar: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    // Filtro periodo
                    ForEach(PeriodFilter.allCases, id: \.self) { period in
                        FilterChip(
                            label: period.rawValue,
                            isSelected: filterPeriod == period
                        ) { filterPeriod = period }
                    }

                    Divider().frame(height: 24)

                    // Filtro categoria
                    ForEach(categorieDisponibili, id: \.self) { cat in
                        FilterChip(
                            label: cat,
                            color: cat == "Tutte" ? .blue : CategoriaSpesa.colorForCategoria(cat),
                            isSelected: filterCategoria == cat
                        ) { filterCategoria = cat }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
            .background(Color.systemBackground)
            Divider()
        }
    }

    // MARK: - List

    private var list: some View {
        List {
            // Header totale
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Totale")
                            .font(.caption).foregroundColor(.secondary)
                        Text("€\(String(format: "%.2f", totalFiltered))")
                            .font(.title2).fontWeight(.bold)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Voci")
                            .font(.caption).foregroundColor(.secondary)
                        Text("\(filteredExpenses.count)")
                            .font(.title2).fontWeight(.bold).foregroundColor(.blue)
                    }
                }
                .padding(.vertical, 4)
            }

            // Righe
            Section {
                if filteredExpenses.isEmpty {
                    ContentUnavailableView(
                        "Nessuna spesa",
                        systemImage: "tray",
                        description: Text("Prova a cambiare i filtri")
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 30)
                } else {
                    ForEach(filteredExpenses) { spesa in
                        ExpenseRowFull(spesa: spesa, onDelete: {
                            expenseManager.rimuoviSpesa(spesa)
                        })
                        .contentShape(Rectangle())
                        .onTapGesture { spesaDaModificare = spesa }
                        #if os(macOS)
                        .contextMenu {
                            Button { spesaDaModificare = spesa } label: {
                                Label("Modifica", systemImage: "pencil")
                            }
                            Button(role: .destructive) {
                                expenseManager.rimuoviSpesa(spesa)
                            } label: {
                                Label("Elimina", systemImage: "trash")
                            }
                        }
                        #endif
                    }
                    #if os(iOS)
                    .onDelete { indexSet in
                        indexSet.map { filteredExpenses[$0] }
                            .forEach { expenseManager.rimuoviSpesa($0) }
                    }
                    #endif
                }
            }
        }
        #if os(macOS)
        .searchable(text: $searchText, prompt: "Cerca per nome o categoria")
        #endif
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .automatic) {
            Menu {
                Section("Ordina per") {
                    ForEach(SortOption.allCases, id: \.self) { option in
                        Button {
                            sortOption = option
                        } label: {
                            Label(
                                option.rawValue,
                                systemImage: sortOption == option ? "checkmark" : "arrow.up.arrow.down"
                            )
                        }
                    }
                }
            } label: {
                Image(systemName: "arrow.up.arrow.down.circle")
            }
        }
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let label: String
    var color: Color = .blue
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(isSelected ? color.opacity(0.2) : Color.secondary.opacity(0.1))
                )
                .foregroundColor(isSelected ? color : .secondary)
                .overlay(
                    Capsule()
                        .strokeBorder(isSelected ? color : Color.clear, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - ExpenseRowFull

struct ExpenseRowFull: View {
    let spesa: CategoriaSpesa
    var onDelete: (() -> Void)? = nil

    private var formattedDate: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        f.locale = Locale(identifier: "it_IT")
        return f.string(from: spesa.data)
    }

    var body: some View {
        HStack(spacing: 12) {
            // Barra colore categoria
            RoundedRectangle(cornerRadius: 4)
                .fill(spesa.colore)
                .frame(width: 4, height: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text(spesa.nome)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    // Badge categoria
                    Text(spesa.categoria)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(spesa.colore.opacity(0.15)))
                        .foregroundColor(spesa.colore)

                    Text(formattedDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Text("€\(String(format: "%.2f", spesa.importo))")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)

            #if os(macOS)
            if let onDelete {
                Button(action: onDelete) {
                    Image(systemName: "trash").foregroundColor(.red)
                }
                .buttonStyle(.plain)
            }
            #endif
        }
        .padding(.vertical, 4)
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
