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
    @State private var selectedPeriod: TimePeriod = .threeMonths
    @State private var selectedCategory: String?
    
    // MARK: - Enums
    
    enum TimePeriod: String, CaseIterable {
        case oneMonth = "1 Mese"
        case threeMonths = "3 Mesi"
        case sixMonths = "6 Mesi"
        case oneYear = "1 Anno"
        case all = "Tutto"
        
        var months: Int? {
            switch self {
            case .oneMonth: return 1
            case .threeMonths: return 3
            case .sixMonths: return 6
            case .oneYear: return 12
            case .all: return nil
            }
        }
    }
    
    // MARK: - Computed Properties
    
    /// Spese nel periodo selezionato
    private var filteredExpenses: [CategoriaSpesa] {
        guard let months = selectedPeriod.months else {
            return expenseManager.categorieSpese
        }
        
        let calendar = Calendar.current
        let now = Date()
        guard let cutoffDate = calendar.date(byAdding: .month, value: -months, to: now) else {
            return expenseManager.categorieSpese
        }
        
        return expenseManager.categorieSpese.filter { $0.data >= cutoffDate }
    }
    
    /// Spese raggruppate per categoria
    private var expensesByCategory: [(name: String, amount: Double, color: Color)] {
        let grouped = Dictionary(grouping: filteredExpenses) { $0.nome }
        return grouped.map { name, expenses in
            let total = expenses.reduce(0) { $0 + $1.importo }
            let color = expenses.first?.colore ?? .blue
            return (name, total, color)
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
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                
                // Header con statistiche chiave
                statisticsHeader
                
                // Grafico a barre - Spese per categoria
                categoryBarChart
                
                // Grafico a linee - Andamento mensile
                monthlyLineChart
                
                // Grafico a torta - Distribuzione
                distributionPieChart
                
                Spacer(minLength: 20)
            }
            .padding(.horizontal, 16)
        }
        .navigationTitle("Statistiche")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                periodFilterMenu
            }
        }
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
                    title: "Periodo",
                    value: selectedPeriod.rawValue,
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
    private var distributionPieChart: some View {
        ChartCard(title: "Distribuzione per Categoria") {
            if expensesByCategory.isEmpty {
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
    
    /// Menu filtro periodo
    private var periodFilterMenu: some View {
        Menu {
            ForEach(TimePeriod.allCases, id: \.self) { period in
                Button(action: { selectedPeriod = period }) {
                    Label(
                        period.rawValue,
                        systemImage: selectedPeriod == period ? "checkmark" : "calendar"
                    )
                }
            }
        } label: {
            Image(systemName: "slider.horizontal.3")
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
                .fill(Color(.systemBackground))
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
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
        )
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
