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
import Charts

struct HomeView: View {
    @EnvironmentObject var expenseManager: ExpenseManager
    @State private var showingAddExpense = false
    @State private var showingExportSheet = false
    @State private var showingImportPicker = false
    @State private var showingBankImport = false
    @State private var exportFileURL: URL?
    @State private var alertItem: ImportExportAlert?

    // MARK: - Computed Properties

    private var calendar: Calendar { Calendar.current }
    private var now: Date { Date() }

    /// Totale spese del mese precedente (per il trend nell'header)
    private var totaleMesePrecedente: Double {
        guard let lastMonth = calendar.date(byAdding: .month, value: -1, to: now) else { return 0 }
        return expenseManager.categorieSpese
            .filter { calendar.isDate($0.data, equalTo: lastMonth, toGranularity: .month) }
            .reduce(0) { $0 + $1.importo }
    }

    /// Andamento giornaliero del mese corrente (sparkline header)
    private var dailyTotalsCurrentMonth: [(date: Date, amount: Double)] {
        let speseMese = expenseManager.categorieSpese.filter {
            calendar.isDate($0.data, equalTo: now, toGranularity: .month)
        }
        let grouped = Dictionary(grouping: speseMese) { calendar.startOfDay(for: $0.data) }
        return grouped
            .map { (date: $0.key, amount: $0.value.reduce(0) { $0 + $1.importo }) }
            .sorted { $0.date < $1.date }
    }

    /// Spese degli ultimi 30 giorni (fallback se mese corrente vuoto)
    private var speseUltimi30Giorni: [CategoriaSpesa] {
        let cutoff = calendar.date(byAdding: .day, value: -30, to: now) ?? now
        return expenseManager.categorieSpese.filter { $0.data >= cutoff }
    }

    /// Spese del mese corrente
    private var speseMeseCorrente: [CategoriaSpesa] {
        expenseManager.categorieSpese.filter {
            calendar.isDate($0.data, equalTo: now, toGranularity: .month)
        }
    }

    /// Top categorie con fallback a 30g se mese vuoto
    private var topCategoriesData: (items: [(name: String, amount: Double, percent: Double)], periodLabel: String?) {
        let useFallback = speseMeseCorrente.isEmpty
        let dataset = useFallback ? speseUltimi30Giorni : speseMeseCorrente
        let total = dataset.reduce(0) { $0 + $1.importo }
        let grouped = Dictionary(grouping: dataset, by: { $0.categoria })
        let items = grouped
            .map { (name: $0.key, amount: $0.value.reduce(0) { $0 + $1.importo }) }
            .map { (name: $0.name, amount: $0.amount, percent: total > 0 ? $0.amount / total * 100 : 0) }
            .sorted { $0.amount > $1.amount }
        return (items, useFallback ? "ultimi 30 giorni" : nil)
    }

    /// Andamento ultimi 12 mesi: top 5 categorie più costose PER MESE
    private var monthlyTrend12MonthsByCategory: (data: [TrendStackPoint], legend: [String], months: [String]) {
        // 1. Lista mesi (label + Date)
        var monthsList: [(date: Date, label: String)] = []
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        formatter.locale = Locale(identifier: "it_IT")
        for offset in (0..<12).reversed() {
            guard let monthDate = calendar.date(byAdding: .month, value: -offset, to: now) else { continue }
            let comps = calendar.dateComponents([.year, .month], from: monthDate)
            let monthStart = calendar.date(from: comps) ?? monthDate
            monthsList.append((monthStart, formatter.string(from: monthStart).capitalized))
        }

        // 2. Filtra spese degli ultimi 12 mesi
        guard let firstMonth = monthsList.first?.date else {
            return (data: [], legend: [], months: [])
        }
        let spese12 = expenseManager.categorieSpese.filter { $0.data >= firstMonth }
        guard !spese12.isEmpty else {
            return (data: [], legend: [], months: monthsList.map { $0.label })
        }

        // 3. Per ogni mese, trova le top 3 categorie di quel mese
        var data: [TrendStackPoint] = []
        var categoryTotalsAcrossMonths: [String: Double] = [:]
        for month in monthsList {
            let monthSpese = spese12.filter {
                calendar.isDate($0.data, equalTo: month.date, toGranularity: .month)
            }
            let grouped = Dictionary(grouping: monthSpese, by: { $0.categoria })
                .map { (cat: $0.key, amount: $0.value.reduce(0) { $0 + $1.importo }) }
                .sorted { $0.amount > $1.amount }
            let top5 = grouped.prefix(5)
            for item in top5 {
                data.append(TrendStackPoint(month: month.label, category: item.cat, amount: item.amount))
                categoryTotalsAcrossMonths[item.cat, default: 0] += item.amount
            }
        }

        // 4. Legenda: tutte le categorie che compaiono almeno una volta nei top 3,
        //    ordinate per spesa totale (decrescente)
        let legend = categoryTotalsAcrossMonths
            .sorted { $0.value > $1.value }
            .map { $0.key }

        return (data: data, legend: legend, months: monthsList.map { $0.label })
    }

    /// Ultimi 6 movimenti registrati
    private var recentExpenses: [CategoriaSpesa] {
        Array(expenseManager.categorieSpese.sorted { $0.data > $1.data }.prefix(6))
    }

    /// Insights calcolati (max 3 card). Se mese corrente vuoto → fallback ultimi 30 giorni.
    private var insightsData: (items: [InsightItem], periodLabel: String?) {
        var result: [InsightItem] = []
        let useFallback = speseMeseCorrente.isEmpty
        let dataset = useFallback ? speseUltimi30Giorni : speseMeseCorrente
        let totalDataset = dataset.reduce(0) { $0 + $1.importo }

        // 1. Stima fine mese (solo se NON in fallback, altrimenti totale 30g)
        if !useFallback {
            let dayOfMonth = calendar.component(.day, from: now)
            let daysInMonth = calendar.range(of: .day, in: .month, for: now)?.count ?? 30
            if dayOfMonth > 0 && totalDataset > 0 {
                let proiezione = totalDataset / Double(dayOfMonth) * Double(daysInMonth)
                result.append(InsightItem(
                    icon: "chart.line.uptrend.xyaxis",
                    color: .indigo,
                    title: "Stima fine mese",
                    detail: "€\(String(format: "%.0f", proiezione))"
                ))
            }
        } else if totalDataset > 0 {
            result.append(InsightItem(
                icon: "calendar",
                color: .indigo,
                title: "Totale 30 giorni",
                detail: "€\(String(format: "%.0f", totalDataset))"
            ))
        }

        // 2. Confronto categorie vs media ultimi 3 mesi/periodi precedenti
        let grouped = Dictionary(grouping: dataset, by: { $0.categoria })
        var deltas: [(category: String, delta: Double, current: Double)] = []
        for (cat, current) in grouped {
            let currentTotal = current.reduce(0) { $0 + $1.importo }
            var sumPrev: Double = 0
            var n = 0
            for offset in 1...3 {
                if useFallback {
                    // Confronto con periodi 30g precedenti
                    guard let from = calendar.date(byAdding: .day, value: -30 * (offset + 1), to: now),
                          let to   = calendar.date(byAdding: .day, value: -30 * offset, to: now) else { continue }
                    let periodTotal = expenseManager.categorieSpese
                        .filter { $0.data >= from && $0.data < to && $0.categoria == cat }
                        .reduce(0) { $0 + $1.importo }
                    sumPrev += periodTotal
                    n += 1
                } else {
                    // Confronto con ultimi 3 mesi pieni
                    guard let monthDate = calendar.date(byAdding: .month, value: -offset, to: now) else { continue }
                    let monthTotal = expenseManager.categorieSpese
                        .filter { calendar.isDate($0.data, equalTo: monthDate, toGranularity: .month) && $0.categoria == cat }
                        .reduce(0) { $0 + $1.importo }
                    sumPrev += monthTotal
                    n += 1
                }
            }
            let avgPrev = n > 0 ? sumPrev / Double(n) : 0
            if avgPrev > 20 {
                let delta = (currentTotal - avgPrev) / avgPrev * 100
                deltas.append((cat, delta, currentTotal))
            }
        }
        let mediaLabel = useFallback ? "vs 90gg precedenti" : "vs ultimi 3 mesi"
        if let topUp = deltas.max(by: { $0.delta < $1.delta }), topUp.delta > 25 {
            result.append(InsightItem(
                icon: "exclamationmark.triangle.fill",
                color: .orange,
                title: "Sopra media: \(topUp.category)",
                detail: "+\(Int(topUp.delta))% \(mediaLabel)"
            ))
        }
        if let topDown = deltas.min(by: { $0.delta < $1.delta }), topDown.delta < -25 {
            result.append(InsightItem(
                icon: "arrow.down.circle.fill",
                color: .green,
                title: "Sotto media: \(topDown.category)",
                detail: "\(Int(topDown.delta))% \(mediaLabel)"
            ))
        }

        return (result, useFallback ? "ultimi 30 giorni" : nil)
    }

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
        .sheet(isPresented: $showingBankImport) {
            BankImportView()
                .environmentObject(expenseManager)
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
        // Hero header full-width con sparkline
        HeaderCard(
            totaleMensile: expenseManager.totaleMensile,
            totaleAnno: expenseManager.totaleAnno,
            totaleMesePrecedente: totaleMesePrecedente,
            mediaMensile: expenseManager.mediaMensile,
            dailyTotals: dailyTotalsCurrentMonth
        )

        // Pulsante aggiungi spesa
        AddExpenseButton {
            showingAddExpense = true
        }

        // Su macOS, link espliciti a Lista e Statistiche (sostituisce la tab bar iOS)
        #if os(macOS)
        HStack(spacing: 12) {
            NavigationLink {
                ExpenseListView().environmentObject(expenseManager)
            } label: {
                Label("Lista Spese", systemImage: "list.bullet")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            NavigationLink {
                StatisticsView().environmentObject(expenseManager)
            } label: {
                Label("Statistiche", systemImage: "chart.bar.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.indigo)
        }
        #endif

        // Riga 1: Trend annuale stacked per categoria
        PanelTrendAnnuale(
            data: monthlyTrend12MonthsByCategory.data,
            legend: monthlyTrend12MonthsByCategory.legend,
            months: monthlyTrend12MonthsByCategory.months
        )

        // Riga 2: 2 colonne (top categorie + ultimi movimenti)
        let topCat = topCategoriesData
        #if os(macOS)
        HStack(alignment: .top, spacing: 16) {
            PanelTopCategorie(items: topCat.items, periodLabel: topCat.periodLabel)
            PanelUltimiMovimenti(items: recentExpenses)
        }
        #else
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 320, maximum: .infinity), spacing: 16)],
            spacing: 16
        ) {
            PanelTopCategorie(items: topCat.items, periodLabel: topCat.periodLabel)
            PanelUltimiMovimenti(items: recentExpenses)
        }
        #endif

        // Riga 3: Insights full-width (card con sotto-card orizzontali)
        let ins = insightsData
        PanelInsights(items: ins.items, periodLabel: ins.periodLabel)
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
            
            Section("Importazione Banca") {
                Button(action: { showingBankImport = true }) {
                    Label("Importa Estratto Conto", systemImage: "doc.text.fill")
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

// MARK: - Insight Model

struct InsightItem: Identifiable {
    let id = UUID()
    let icon: String
    let color: Color
    let title: String
    let detail: String
}

// MARK: - Trend Data Point

struct TrendStackPoint: Identifiable {
    let id = UUID()
    let month: String
    let category: String
    let amount: Double
}

// MARK: - Panel: Top Categorie

struct PanelTopCategorie: View {
    let items: [(name: String, amount: Double, percent: Double)]
    var periodLabel: String? = nil
    var openList: () -> Void = {}

    var body: some View {
        DashboardCard(
            title: "Top categorie",
            icon: "trophy.fill",
            iconColor: .orange,
            subtitle: periodLabel
        ) {
            if items.isEmpty {
                emptyState
            } else {
                VStack(spacing: 10) {
                    ForEach(Array(items.prefix(5).enumerated()), id: \.offset) { _, item in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Circle()
                                    .fill(CategoriaSpesa.colorForCategoria(item.name))
                                    .frame(width: 8, height: 8)
                                Text(item.name)
                                    .font(.subheadline.weight(.medium))
                                    .lineLimit(1)
                                Spacer()
                                Text("€\(String(format: "%.0f", item.amount))")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(.primary)
                            }
                            // Barra di progresso
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(Color.secondary.opacity(0.12))
                                        .frame(height: 6)
                                    Capsule()
                                        .fill(CategoriaSpesa.colorForCategoria(item.name))
                                        .frame(width: max(4, geo.size.width * CGFloat(item.percent / 100)), height: 6)
                                }
                            }
                            .frame(height: 6)
                            Text("\(String(format: "%.0f", item.percent))% del mese")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.bar")
                .font(.title)
                .foregroundColor(.secondary)
            Text("Nessuna spesa questo mese")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
    }
}

// MARK: - Panel: Trend Annuale (12 mesi, stacked per categoria)

struct PanelTrendAnnuale: View {
    let data: [TrendStackPoint]
    let legend: [String]
    let months: [String]

    private var totalYear: Double { data.reduce(0) { $0 + $1.amount } }
    private var avgMonth: Double {
        // Conta solo i mesi che hanno almeno una spesa
        let monthsWithData = Set(data.filter { $0.amount > 0 }.map { $0.month })
        guard !monthsWithData.isEmpty else { return 0 }
        return totalYear / Double(monthsWithData.count)
    }

    /// Mappa categoria → colore
    private func colorFor(_ category: String) -> Color {
        CategoriaSpesa.colorForCategoria(category)
    }

    /// Importo massimo per ogni mese (per piazzare la label solo sulla barra più alta)
    private var maxPerMonth: [String: Double] {
        Dictionary(grouping: data, by: { $0.month })
            .mapValues { $0.map(\.amount).max() ?? 0 }
    }

    var body: some View {
        DashboardCard(title: "Trend ultimi 12 mesi", icon: "chart.bar.fill", iconColor: .indigo, minHeight: 320) {
            if data.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "chart.bar")
                        .font(.title)
                        .foregroundColor(.secondary)
                    Text("Dati insufficienti per il trend")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    // Sub-stats inline
                    HStack(spacing: 28) {
                        statColumn(label: "Totale 12 mesi", value: totalYear, color: .indigo)
                        statColumn(label: "Media mensile",   value: avgMonth,   color: .green)
                        Spacer()
                    }

                    // Chart + legenda affiancati
                    HStack(alignment: .top, spacing: 20) {
                        chartView
                            .frame(maxWidth: .infinity)
                            .frame(height: 240)

                        legendView
                            .frame(width: 160)
                    }
                }
            }
        }
    }

    private var chartView: some View {
        Chart(data) { item in
            BarMark(
                x: .value("Mese", item.month),
                y: .value("Spesa", item.amount),
                width: .ratio(0.85)
            )
            .foregroundStyle(by: .value("Categoria", item.category))
            .position(by: .value("Categoria", item.category))   // ← affiancate, non impilate
            .annotation(position: .top, alignment: .center, spacing: 2) {
                // Mostra label solo sulla barra più alta del mese
                if item.amount == maxPerMonth[item.month] {
                    Text("€\(Int(item.amount))")
                        .font(.caption2.weight(.medium))
                        .foregroundColor(.secondary)
                }
            }
        }
        .chartForegroundStyleScale(
            domain: legend,
            range: legend.map { colorFor($0) }
        )
        .chartLegend(.hidden)  // legenda custom a destra
        .chartYAxis {
            AxisMarks(position: .leading) { _ in
                AxisGridLine()
                AxisValueLabel().font(.caption2)
            }
        }
        .chartXAxis {
            AxisMarks { _ in
                AxisValueLabel().font(.caption2)
            }
        }
    }

    private var legendView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Categorie")
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)
                .padding(.bottom, 2)
            ForEach(legend, id: \.self) { cat in
                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(colorFor(cat))
                        .frame(width: 12, height: 12)
                    Text(cat)
                        .font(.caption)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 0)
        }
    }

    private func statColumn(label: String, value: Double, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("€\(String(format: "%.2f", value))")
                .font(.title3.weight(.semibold))
                .foregroundColor(color)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Panel: Ultimi Movimenti

struct PanelUltimiMovimenti: View {
    let items: [CategoriaSpesa]
    @EnvironmentObject var expenseManager: ExpenseManager

    private func relativeDateLabel(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date)     { return "oggi" }
        if calendar.isDateInYesterday(date) { return "ieri" }
        let days = calendar.dateComponents([.day], from: date, to: Date()).day ?? 0
        if days < 7 { return "\(days)g fa" }
        let f = DateFormatter()
        f.dateFormat = "d MMM"
        f.locale = Locale(identifier: "it_IT")
        return f.string(from: date)
    }

    var body: some View {
        DashboardCard(title: "Ultimi movimenti", icon: "clock.fill", iconColor: .blue) {
            if items.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "tray")
                        .font(.title)
                        .foregroundColor(.secondary)
                    Text("Nessun movimento")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
            } else {
                VStack(spacing: 10) {
                    ForEach(items) { spesa in
                        HStack(spacing: 10) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(spesa.colore)
                                .frame(width: 3, height: 30)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(spesa.nome)
                                    .font(.caption.weight(.medium))
                                    .lineLimit(1)
                                Text(relativeDateLabel(spesa.data))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text("€\(String(format: "%.2f", spesa.importo))")
                                .font(.caption.weight(.semibold))
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Panel: Insights (horizontal sub-cards)

struct PanelInsights: View {
    let items: [InsightItem]
    var periodLabel: String? = nil

    var body: some View {
        DashboardCard(
            title: "Insights",
            icon: "lightbulb.fill",
            iconColor: .yellow,
            subtitle: periodLabel,
            minHeight: 140
        ) {
            if items.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.title)
                        .foregroundColor(.secondary)
                    Text("Aggiungi più spese per vedere insights personalizzati")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 240, maximum: .infinity), spacing: 12)],
                    spacing: 12
                ) {
                    ForEach(items) { item in
                        insightSubCard(item)
                    }
                }
            }
        }
    }

    private func insightSubCard(_ item: InsightItem) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: item.icon)
                .font(.title3)
                .foregroundColor(item.color)
                .frame(width: 36, height: 36)
                .background(Circle().fill(item.color.opacity(0.15)))
            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(item.detail)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.secondary.opacity(0.08))
        )
    }
}

// MARK: - Dashboard Card Container

struct DashboardCard<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    let subtitle: String?
    let minHeight: CGFloat
    let content: Content

    init(
        title: String,
        icon: String,
        iconColor: Color,
        subtitle: String? = nil,
        minHeight: CGFloat = 320,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.icon = icon
        self.iconColor = iconColor
        self.subtitle = subtitle
        self.minHeight = minHeight
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                Text(title)
                    .font(.headline)
                if let subtitle {
                    Text(subtitle)
                        .font(.caption.weight(.medium))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color.secondary.opacity(0.12)))
                }
                Spacer()
            }
            content
            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: minHeight, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.systemBackground)
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
}


