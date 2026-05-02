//
//  StatisticsView.swift
//  MoneyTracker
//
//  Created by Assistant on 09/12/24.
//

/*
 VIEW - StatisticsView (Schermata Statistiche e Grafici)
 
 Questa schermata mostra grafici interattivi per analizzare le spese nel tempo.
 
 CONCETTI SWIFT/SWIFTUI UTILIZZATI:
 • Swift Charts: Framework nativo Apple per grafici
 • BarChart: Grafico a barre per confronto categorie
 • LineChart: Grafico a linee per andamento temporale
 • SectorMark: Grafico a torta (pie chart)
 • Chart customization: Colori, assi, legenda
 • DateFormatter: Formattazione date per assi temporali
 
 FUNZIONALITÀ:
 - Grafico spese per categoria (barre)
 - Andamento mensile spese (linee)
 - Distribuzione percentuale (torta)
 - Filtri temporali (1 mese, 3 mesi, anno, tutto)
 - Statistiche chiave
 - Interattività con tap
 
 UTILIZZO:
 - Accessibile dalla HomeView via tab o pulsante
 - NavigationLink da dashboard
*/

import SwiftUI
import Charts

struct StatisticsView: View {
    // MARK: - Environment
    @EnvironmentObject var expenseManager: ExpenseManager
    
    // MARK: - State

    @State private var dateFrom: Date = Calendar.current.date(byAdding: .month, value: -3, to: Date()) ?? Date()
    @State private var dateTo: Date   = Date()
    @State private var selectedCategories: Set<String> = Set(CategoriaSpesa.allCategorie)
    @State private var showCategoryPicker: Bool = false

    // MARK: - Computed Properties

    /// Spese filtrate per range date + categorie selezionate
    private var filteredExpenses: [CategoriaSpesa] {
        let calendar = Calendar.current
        // Estendi dateTo a fine giornata per includere spese registrate quel giorno
        let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: dateTo) ?? dateTo
        return expenseManager.categorieSpese.filter { spesa in
            spesa.data >= dateFrom &&
            spesa.data <= endOfDay &&
            selectedCategories.contains(spesa.categoria)
        }
    }

    /// Etichetta del bottone categorie (es. "Tutte le categorie", "5 selezionate")
    private var categoriesButtonLabel: String {
        let total = CategoriaSpesa.allCategorie.count
        if selectedCategories.count == total { return "Tutte le categorie" }
        if selectedCategories.isEmpty         { return "Nessuna categoria" }
        if selectedCategories.count == 1      { return selectedCategories.first ?? "1 categoria" }
        return "\(selectedCategories.count) di \(total) selezionate"
    }

    /// Numero di giorni nel range selezionato
    private var daysInRange: Int {
        let calendar = Calendar.current
        let from = calendar.startOfDay(for: dateFrom)
        let to   = calendar.startOfDay(for: dateTo)
        let days = calendar.dateComponents([.day], from: from, to: to).day ?? 0
        return max(days + 1, 1)
    }
    
    /// Spese raggruppate per categoria
    private var expensesByCategory: [(name: String, amount: Double, color: Color)] {
        let grouped = Dictionary(grouping: filteredExpenses) { $0.categoria }
        return grouped.map { categoria, expenses in
            let total = expenses.reduce(0) { $0 + $1.importo }
            let color = CategoriaSpesa.colorForCategoria(categoria)
            return (categoria, total, color)
        }
        .sorted { $0.amount > $1.amount }
    }
    
    /// Spese raggruppate per mese
    private var expensesByMonth: [(month: String, amount: Double)] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredExpenses) { expense in
            calendar.dateComponents([.year, .month], from: expense.data)
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        formatter.locale = Locale(identifier: "it_IT")
        
        return grouped.compactMap { components, expenses -> (String, Double, Date)? in
            let total = expenses.reduce(0) { $0 + $1.importo }
            guard let date = calendar.date(from: components) else { return nil }
            let monthName = formatter.string(from: date)
            return (monthName, total, date)
        }
        .sorted { $0.2 < $1.2 }  // Ordina per data (terzo elemento della tupla)
        .map { ($0.0, $0.1) }     // Ritorna solo nome mese e importo
    }
    
    /// Totale periodo
    private var totalPeriod: Double {
        filteredExpenses.reduce(0) { $0 + $1.importo }
    }

    /// Media per mese
    private var averagePerMonth: Double {
        let months = max(expensesByMonth.count, 1)
        return totalPeriod / Double(months)
    }

    /// Top 10 spese più costose nel periodo filtrato
    private var topMovimenti: [CategoriaSpesa] {
        Array(filteredExpenses.sorted { $0.importo > $1.importo }.prefix(10))
    }
    
    // MARK: - Body
    
    var body: some View {
        #if os(macOS)
        // ────────────────── macOS: sidebar + 2x2 grid ──────────────────
        HStack(spacing: 0) {
            sidebarFiltri
                .frame(width: 280)
                .background(Color.systemGroupedBackground)
            Divider()
            ScrollView {
                mainContent
                    .padding(20)
            }
        }
        .navigationTitle("Statistiche")
        #else
        // ────────────────── iOS: scroll verticale ──────────────────
        ScrollView {
            VStack(spacing: 20) {
                filterSection
                statisticsHeader
                categoryBarChart
                monthlyLineChart
                distributionPieChart
                topMovimentiPanel
                Spacer(minLength: 20)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
        }
        .navigationTitle("Statistiche")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showCategoryPicker) {
            MultiCategoryPickerSheet(selected: $selectedCategories)
        }
        #endif
    }

    // MARK: - macOS Layout

    /// Contenuto principale macOS: KPI row + 2x2 chart grid
    @ViewBuilder
    private var mainContent: some View {
        VStack(spacing: 16) {
            // KPI row (4 cards in linea)
            HStack(spacing: 12) {
                StatCard(title: "Totale Periodo",
                         value: "€\(String(format: "%.2f", totalPeriod))",
                         icon: "chart.bar.fill", color: .blue)
                StatCard(title: "Media Mensile",
                         value: "€\(String(format: "%.2f", averagePerMonth))",
                         icon: "chart.line.uptrend.xyaxis", color: .green)
                StatCard(title: "Numero Spese",
                         value: "\(filteredExpenses.count)",
                         icon: "number", color: .orange)
                StatCard(title: "Giorni",
                         value: "\(daysInRange)",
                         icon: "calendar", color: .purple)
            }

            // 2x2 chart grid
            HStack(alignment: .top, spacing: 16) {
                categoryBarChart
                monthlyLineChart
            }
            HStack(alignment: .top, spacing: 16) {
                distributionPieChart
                topMovimentiPanel
            }
        }
    }

    // MARK: - Sidebar (macOS)

    private var sidebarFiltri: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // ── Sezione PERIODO ──
                sidebarSection(title: "Periodo", icon: "calendar") {
                    VStack(alignment: .leading, spacing: 10) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Da").font(.caption).foregroundColor(.secondary)
                            DatePicker("", selection: $dateFrom, in: ...dateTo, displayedComponents: .date)
                                .labelsHidden()
                                .environment(\.locale, Locale(identifier: "it_IT"))
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text("A").font(.caption).foregroundColor(.secondary)
                            DatePicker("", selection: $dateTo, in: dateFrom..., displayedComponents: .date)
                                .labelsHidden()
                                .environment(\.locale, Locale(identifier: "it_IT"))
                        }
                    }
                }

                // ── Sezione PRESET ──
                sidebarSection(title: "Preset", icon: "bolt.fill") {
                    VStack(spacing: 6) {
                        sidebarPresetButton("Ultimo mese")    { setRange(months: 1) }
                        sidebarPresetButton("Ultimi 3 mesi")  { setRange(months: 3) }
                        sidebarPresetButton("Ultimi 6 mesi")  { setRange(months: 6) }
                        sidebarPresetButton("Ultimo anno")    { setRange(months: 12) }
                        Divider()
                        let currentYear = Calendar.current.component(.year, from: Date())
                        ForEach((2022...currentYear).reversed(), id: \.self) { year in
                            sidebarPresetButton("\(year)") { setRangeYear(year) }
                        }
                        Divider()
                        sidebarPresetButton("Tutto") { setRangeAll() }
                        Button(role: .destructive) { resetFilters() } label: {
                            HStack {
                                Image(systemName: "arrow.counterclockwise")
                                Text("Reset filtri")
                                Spacer()
                            }
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.red)
                    }
                }

                // ── Sezione CATEGORIE ──
                sidebarSection(
                    title: "Categorie",
                    icon: "tag.fill",
                    trailing: Text("\(selectedCategories.count)/\(CategoriaSpesa.allCategorie.count)")
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(.secondary)
                ) {
                    VStack(spacing: 4) {
                        // Quick toggle Tutte/Nessuna
                        HStack(spacing: 6) {
                            Button("Tutte") { selectedCategories = Set(CategoriaSpesa.allCategorie) }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                                .tint(.indigo)
                            Button("Nessuna") { selectedCategories.removeAll() }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            Spacer()
                        }
                        .padding(.bottom, 4)

                        ForEach(CategoriaSpesa.allCategorie, id: \.self) { cat in
                            Button {
                                if selectedCategories.contains(cat) {
                                    selectedCategories.remove(cat)
                                } else {
                                    selectedCategories.insert(cat)
                                }
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: selectedCategories.contains(cat) ? "checkmark.square.fill" : "square")
                                        .foregroundColor(selectedCategories.contains(cat) ? .indigo : .secondary)
                                    Circle()
                                        .fill(CategoriaSpesa.colorForCategoria(cat))
                                        .frame(width: 8, height: 8)
                                    Text(cat)
                                        .font(.caption)
                                        .foregroundColor(.primary)
                                    Spacer()
                                }
                                .padding(.vertical, 3)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(16)
        }
    }

    private func sidebarPresetButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title).font(.caption)
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.secondary.opacity(0.08))
        )
    }

    @ViewBuilder
    private func sidebarSection<Content: View, Trailing: View>(
        title: String,
        icon: String,
        @ViewBuilder trailing: () -> Trailing = { EmptyView() },
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(.indigo)
                Text(title.uppercased())
                    .font(.caption.weight(.bold))
                    .foregroundColor(.secondary)
                    .tracking(0.6)
                Spacer()
                trailing()
            }
            content()
        }
    }

    // Overload semplice per chiamare senza trailing
    @ViewBuilder
    private func sidebarSection<Content: View>(
        title: String,
        icon: String,
        trailing: some View,
        @ViewBuilder content: () -> Content
    ) -> some View {
        sidebarSection(title: title, icon: icon, trailing: { trailing }, content: content)
    }

    // MARK: - Top Movimenti Panel

    private var topMovimentiPanel: some View {
        ChartCard(title: "Top movimenti") {
            if topMovimenti.isEmpty {
                emptyChartPlaceholder
            } else {
                VStack(spacing: 10) {
                    ForEach(topMovimenti) { spesa in
                        HStack(spacing: 10) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(spesa.colore)
                                .frame(width: 3, height: 32)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(spesa.nome)
                                    .font(.subheadline.weight(.medium))
                                    .lineLimit(1)
                                HStack(spacing: 6) {
                                    Text(spesa.categoria)
                                        .font(.caption2.weight(.medium))
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 1)
                                        .background(Capsule().fill(spesa.colore.opacity(0.15)))
                                        .foregroundColor(spesa.colore)
                                    Text(formatDate(spesa.data))
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                            Text("€\(String(format: "%.2f", spesa.importo))")
                                .font(.subheadline.weight(.semibold))
                        }
                    }
                }
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "d MMM"
        f.locale = Locale(identifier: "it_IT")
        return f.string(from: date)
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
                showCategoryPicker = true
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
        selectedCategories = Set(CategoriaSpesa.allCategorie)
    }
    
    // MARK: - Components
    
    /// Header con statistiche chiave
    private var statisticsHeader: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                StatCard(
                    title: "Totale Periodo",
                    value: "€\(String(format: "%.2f", totalPeriod))",
                    icon: "chart.bar.fill",
                    color: .blue
                )
                
                StatCard(
                    title: "Media Mensile",
                    value: "€\(String(format: "%.2f", averagePerMonth))",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .green
                )
            }
            
            HStack(spacing: 16) {
                StatCard(
                    title: "Numero Spese",
                    value: "\(filteredExpenses.count)",
                    icon: "number",
                    color: .orange
                )
                
                StatCard(
                    title: "Giorni",
                    value: "\(daysInRange)",
                    icon: "calendar",
                    color: .purple
                )
            }
        }
    }
    
    /// Grafico a barre per categorie
    private var categoryBarChart: some View {
        ChartCard(title: "Spese per Categoria") {
            if expensesByCategory.isEmpty {
                emptyChartPlaceholder
            } else {
                Chart(expensesByCategory, id: \.name) { item in
                    BarMark(
                        x: .value("Importo", item.amount),
                        y: .value("Categoria", item.name)
                    )
                    .foregroundStyle(item.color.gradient)
                    .annotation(position: .trailing) {
                        Text("€\(Int(item.amount))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .chartXAxis {
                    AxisMarks(position: .bottom)
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .frame(height: CGFloat(max(expensesByCategory.count * 50, 200)))
            }
        }
    }
    
    /// Grafico a linee per andamento mensile
    private var monthlyLineChart: some View {
        ChartCard(title: "Andamento Mensile") {
            if expensesByMonth.isEmpty {
                emptyChartPlaceholder
            } else {
                Chart {
                    ForEach(Array(expensesByMonth.enumerated()), id: \.offset) { index, item in
                        LineMark(
                            x: .value("Mese", item.month),
                            y: .value("Importo", item.amount)
                        )
                        .foregroundStyle(.blue.gradient)
                        .interpolationMethod(.catmullRom)
                        
                        AreaMark(
                            x: .value("Mese", item.month),
                            y: .value("Importo", item.amount)
                        )
                        .foregroundStyle(.blue.opacity(0.1).gradient)
                        .interpolationMethod(.catmullRom)
                        
                        PointMark(
                            x: .value("Mese", item.month),
                            y: .value("Importo", item.amount)
                        )
                        .foregroundStyle(.blue)
                        .annotation(position: .top) {
                            Text("€\(Int(item.amount))")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .frame(height: 220)
            }
        }
    }
    
    /// Grafico a torta per distribuzione
    /// Grafico a torta — protetto contro divisione per zero quando totalPeriod == 0
    private var distributionPieChart: some View {
        ChartCard(title: "Distribuzione per Categoria") {
            if expensesByCategory.isEmpty || totalPeriod <= 0 {
                emptyChartPlaceholder
            } else {
                Chart(expensesByCategory.prefix(5), id: \.name) { item in
                    SectorMark(
                        angle: .value("Importo", item.amount),
                        innerRadius: .ratio(0.6),
                        angularInset: 1.5
                    )
                    .foregroundStyle(item.color.gradient)
                    .annotation(position: .overlay) {
                        let percentage = (item.amount / totalPeriod) * 100
                        if percentage > 5 {
                            Text("\(Int(percentage))%")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                    }
                }
                .frame(height: 250)
                
                // Legenda
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(expensesByCategory.prefix(5), id: \.name) { item in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(item.color)
                                .frame(width: 12, height: 12)
                            
                            Text(item.name)
                                .font(.subheadline)
                            
                            Spacer()
                            
                            Text("€\(String(format: "%.2f", item.amount))")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Text("(\(Int((item.amount / totalPeriod) * 100))%)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.top, 12)
            }
        }
    }
    
    /// Placeholder per grafici vuoti
    private var emptyChartPlaceholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.xyaxis.line")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            
            Text("Nessun dato disponibile")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("Aggiungi spese per vedere i grafici")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Supporting Views

/// Card per statistiche chiave
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                Spacer()
            }
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.systemBackground)
                .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
        )
    }
}

/// Card container per grafici
struct ChartCard<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            content
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.systemBackground)
                .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
        )
    }
}

// MARK: - Multi Category Picker Sheet

struct MultiCategoryPickerSheet: View {
    @Binding var selected: Set<String>
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Button {
                            selected = Set(CategoriaSpesa.allCategorie)
                        } label: {
                            Label("Tutte", systemImage: "checkmark.circle.fill")
                        }
                        .buttonStyle(.bordered)
                        .tint(.indigo)

                        Button {
                            selected.removeAll()
                        } label: {
                            Label("Nessuna", systemImage: "xmark.circle")
                        }
                        .buttonStyle(.bordered)
                        .tint(.secondary)

                        Spacer()
                    }
                }
                Section("Categorie (\(selected.count) selezionate)") {
                    ForEach(CategoriaSpesa.allCategorie, id: \.self) { cat in
                        Button {
                            if selected.contains(cat) {
                                selected.remove(cat)
                            } else {
                                selected.insert(cat)
                            }
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: selected.contains(cat) ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(selected.contains(cat) ? .indigo : .secondary)
                                    .font(.title3)
                                Circle()
                                    .fill(CategoriaSpesa.colorForCategoria(cat))
                                    .frame(width: 14, height: 14)
                                Text(cat)
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle("Filtra categorie")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fatto") { dismiss() }
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
struct StatisticsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            StatisticsView()
                .environmentObject(ExpenseManager(mockData: true))
        }
    }
}
