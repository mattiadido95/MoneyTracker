//
//  ExpenseListView.swift
//  MoneyTracker
//

import SwiftUI

struct ExpenseListView: View {

    // MARK: - Environment
    @EnvironmentObject var expenseManager: ExpenseManager

    // MARK: - State

    @State private var dateFrom: Date = Calendar.current.date(byAdding: .month, value: -3, to: Date()) ?? Date()
    @State private var dateTo: Date   = Date()
    @State private var selectedFilterCategories: Set<String> = Set(CategoriaSpesa.allCategorie)
    @State private var showFilterCategoryPicker: Bool = false

    @State private var sortOption: SortOption = .dateNewest
    @State private var searchText: String = ""
    @State private var spesaDaModificare: CategoriaSpesa?
    @State private var visibleCount: Int = 25

    // Selezione multipla (bulk edit)
    @State private var isSelecting: Bool = false
    @State private var selectedIDs: Set<UUID> = []
    @State private var showCategoryPicker: Bool = false

    private let pageSize = 25

    private var allVisibleSelected: Bool {
        !visibleExpenses.isEmpty && visibleExpenses.allSatisfy { selectedIDs.contains($0.id) }
    }

    // MARK: - Enums

    enum SortOption: String, CaseIterable {
        case dateNewest = "Più Recenti"
        case dateOldest = "Più Vecchie"
        case amountHigh = "Importo ↓"
        case amountLow  = "Importo ↑"
    }

    // MARK: - Computed Properties

    /// Etichetta del bottone categorie
    private var categoriesButtonLabel: String {
        let total = CategoriaSpesa.allCategorie.count
        if selectedFilterCategories.count == total { return "Tutte le categorie" }
        if selectedFilterCategories.isEmpty         { return "Nessuna categoria" }
        if selectedFilterCategories.count == 1      { return selectedFilterCategories.first ?? "1 categoria" }
        return "\(selectedFilterCategories.count) di \(total) selezionate"
    }

    private var filteredExpenses: [CategoriaSpesa] {
        let calendar = Calendar.current
        let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: dateTo) ?? dateTo

        var result = expenseManager.categorieSpese.filter { spesa in
            spesa.data >= dateFrom &&
            spesa.data <= endOfDay &&
            selectedFilterCategories.contains(spesa.categoria)
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

    /// Slice visibile in base alla paginazione
    private var visibleExpenses: [CategoriaSpesa] {
        Array(filteredExpenses.prefix(visibleCount))
    }

    private var hasMore: Bool {
        visibleCount < filteredExpenses.count
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            filterSection
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)
            list
        }
        .navigationTitle("Tutte le Spese")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, prompt: "Cerca per nome o categoria")
        #endif
        .toolbar { toolbarContent }
        .safeAreaInset(edge: .bottom) {
            if isSelecting { selectionActionBar }
        }
        .sheet(item: $spesaDaModificare) { spesa in
            AddExpenseView(spesaDaModificare: spesa)
                .environmentObject(expenseManager)
        }
        .sheet(isPresented: $showCategoryPicker) {
            BulkCategoryPickerSheet(
                count: selectedIDs.count,
                onSelect: { cat in
                    applyBulkCategory(cat)
                },
                onCancel: { showCategoryPicker = false }
            )
        }
        .sheet(isPresented: $showFilterCategoryPicker) {
            MultiCategoryPickerSheet(selected: $selectedFilterCategories)
        }
        .onChange(of: dateFrom)                 { _, _ in visibleCount = pageSize }
        .onChange(of: dateTo)                   { _, _ in visibleCount = pageSize }
        .onChange(of: selectedFilterCategories) { _, _ in visibleCount = pageSize }
        .onChange(of: searchText)               { _, _ in visibleCount = pageSize }
        .onChange(of: sortOption)               { _, _ in visibleCount = pageSize }
    }

    // MARK: - Filter Section

    private var filterSection: some View {
        VStack(spacing: 14) {
            // Header sezione + menu preset
            HStack {
                Image(systemName: "slider.horizontal.3")
                    .foregroundColor(.indigo)
                Text("Filtri")
                    .font(.headline)
                Spacer()
                Menu {
                    Section("Periodo rapido") {
                        Button("Ultimo mese")     { setRange(months: 1) }
                        Button("Ultimi 3 mesi")   { setRange(months: 3) }
                        Button("Ultimi 6 mesi")   { setRange(months: 6) }
                        Button("Ultimo anno")     { setRange(months: 12) }
                    }
                    Section("Anno") {
                        let currentYear = Calendar.current.component(.year, from: Date())
                        ForEach((2022...currentYear).reversed(), id: \.self) { year in
                            Button("\(year)") { setRangeYear(year) }
                        }
                    }
                    Section {
                        Button("Tutto") { setRangeAll() }
                        Button("Reset filtri", role: .destructive) { resetFilters() }
                    }
                } label: {
                    Label("Preset", systemImage: "ellipsis.circle")
                        .font(.subheadline)
                        .foregroundColor(.indigo)
                }
            }

            // Date range
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Da")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    DatePicker("", selection: $dateFrom, in: ...dateTo, displayedComponents: .date)
                        .labelsHidden()
                        .environment(\.locale, Locale(identifier: "it_IT"))
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 4) {
                    Text("A")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    DatePicker("", selection: $dateTo, in: dateFrom..., displayedComponents: .date)
                        .labelsHidden()
                        .environment(\.locale, Locale(identifier: "it_IT"))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Multi-select categorie
            Button {
                showFilterCategoryPicker = true
            } label: {
                HStack {
                    Image(systemName: "tag.fill")
                        .foregroundColor(.indigo)
                    Text(categoriesButtonLabel)
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .font(.subheadline)
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.secondary.opacity(0.12))
                )
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.systemBackground)
                .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
        )
    }

    // MARK: - Filter Helpers

    private func setRange(months: Int) {
        let calendar = Calendar.current
        let now = Date()
        dateTo = now
        dateFrom = calendar.date(byAdding: .month, value: -months, to: now) ?? now
    }

    private func setRangeYear(_ year: Int) {
        let calendar = Calendar.current
        let from = calendar.date(from: DateComponents(year: year, month: 1, day: 1)) ?? Date()
        let to   = calendar.date(from: DateComponents(year: year, month: 12, day: 31)) ?? Date()
        dateFrom = from
        dateTo   = to
    }

    private func setRangeAll() {
        let allDates = expenseManager.categorieSpese.map { $0.data }
        dateFrom = allDates.min() ?? Date()
        dateTo   = allDates.max() ?? Date()
    }

    private func resetFilters() {
        let calendar = Calendar.current
        let now = Date()
        dateTo = now
        dateFrom = calendar.date(byAdding: .month, value: -3, to: now) ?? now
        selectedFilterCategories = Set(CategoriaSpesa.allCategorie)
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
                    ForEach(visibleExpenses) { spesa in
                        HStack(spacing: 8) {
                            if isSelecting {
                                Image(systemName: selectedIDs.contains(spesa.id) ? "checkmark.circle.fill" : "circle")
                                    .font(.title3)
                                    .foregroundColor(selectedIDs.contains(spesa.id) ? .indigo : .secondary)
                                    .transition(.opacity.combined(with: .move(edge: .leading)))
                            }
                            ExpenseRowFull(spesa: spesa, onDelete: {
                                expenseManager.rimuoviSpesa(spesa)
                            })
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if isSelecting {
                                toggleSelection(spesa.id)
                            } else {
                                spesaDaModificare = spesa
                            }
                        }
                        #if os(iOS)
                        .onLongPressGesture {
                            if !isSelecting {
                                withAnimation { isSelecting = true }
                                selectedIDs.insert(spesa.id)
                            }
                        }
                        #endif
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
                        indexSet.map { visibleExpenses[$0] }
                            .forEach { expenseManager.rimuoviSpesa($0) }
                    }
                    #endif

                    // Carica altri
                    if hasMore {
                        Button {
                            withAnimation { visibleCount += pageSize }
                        } label: {
                            HStack(spacing: 6) {
                                Text("Carica altri \(min(pageSize, filteredExpenses.count - visibleCount))")
                                    .fontWeight(.medium)
                                Image(systemName: "chevron.down")
                                    .font(.caption)
                            }
                            .foregroundColor(.indigo)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                        }
                        .buttonStyle(.plain)
                    }
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
        ToolbarItem(placement: .automatic) {
            Button(isSelecting ? "Annulla" : "Seleziona") {
                withAnimation {
                    if isSelecting {
                        isSelecting = false
                        selectedIDs.removeAll()
                    } else {
                        isSelecting = true
                    }
                }
            }
        }
    }

    // MARK: - Selection Action Bar

    private var selectionActionBar: some View {
        HStack(spacing: 12) {
            Button {
                if allVisibleSelected {
                    selectedIDs.subtract(visibleExpenses.map { $0.id })
                } else {
                    selectedIDs.formUnion(visibleExpenses.map { $0.id })
                }
            } label: {
                Image(systemName: allVisibleSelected ? "checkmark.square.fill" : "square")
                    .font(.title3)
                    .foregroundColor(.indigo)
            }
            .buttonStyle(.plain)

            Text("\(selectedIDs.count) selezionate")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            Button {
                showCategoryPicker = true
            } label: {
                Label("Cambia categoria", systemImage: "tag.fill")
                    .font(.subheadline.weight(.semibold))
            }
            .buttonStyle(.borderedProminent)
            .tint(.indigo)
            .disabled(selectedIDs.isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .overlay(Divider(), alignment: .top)
    }

    // MARK: - Helpers

    private func toggleSelection(_ id: UUID) {
        if selectedIDs.contains(id) {
            selectedIDs.remove(id)
        } else {
            selectedIDs.insert(id)
        }
    }

    private func applyBulkCategory(_ categoria: String) {
        expenseManager.cambiaCategoriaMultiple(ids: selectedIDs, nuovaCategoria: categoria)
        selectedIDs.removeAll()
        showCategoryPicker = false
        withAnimation { isSelecting = false }
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

// MARK: - Bulk Category Picker Sheet

struct BulkCategoryPickerSheet: View {
    let count: Int
    let onSelect: (String) -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.indigo)
                        Text("\(count) \(count == 1 ? "spesa selezionata" : "spese selezionate")")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                Section("Scegli la nuova categoria") {
                    ForEach(CategoriaSpesa.allCategorie, id: \.self) { cat in
                        Button {
                            onSelect(cat)
                        } label: {
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(CategoriaSpesa.colorForCategoria(cat))
                                    .frame(width: 14, height: 14)
                                Text(cat)
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Cambia categoria")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla", action: onCancel)
                }
            }
        }
        #if os(iOS)
        .presentationDetents([.large])
        #elseif os(macOS)
        .frame(minWidth: 500, idealWidth: 550, minHeight: 600, idealHeight: 700)
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
