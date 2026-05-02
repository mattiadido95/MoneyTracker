import SwiftUI
import Charts

struct HeaderCard: View {
    let totaleMensile: Double
    let totaleAnno: Double
    let totaleMesePrecedente: Double
    let mediaMensile: Double
    let dailyTotals: [(date: Date, amount: Double)]

    // MARK: - Helpers

    private var meseCorrente: String {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        f.locale = Locale(identifier: "it_IT")
        return f.string(from: Date()).capitalized
    }

    private var trend: Double? {
        guard totaleMesePrecedente > 0 else { return nil }
        return ((totaleMensile - totaleMesePrecedente) / totaleMesePrecedente) * 100
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Riga superiore: mese + icona
            HStack(alignment: .top) {
                Text(meseCorrente.uppercased())
                    .font(.caption.weight(.semibold))
                    .tracking(1.2)
                    .foregroundColor(.white.opacity(0.7))
                Spacer()
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.5))
            }

            Spacer().frame(height: 18)

            // Riga centrale: hero amount a sinistra, trend+stats a destra
            HStack(alignment: .bottom, spacing: 20) {
                // Sinistra: importo principale
                VStack(alignment: .leading, spacing: 4) {
                    Text("€\(String(format: "%.2f", totaleMensile))")
                        .font(.system(size: 52, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                    Text("spese questo mese")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.65))
                }

                Spacer()

                // Destra: trend + due stats
                VStack(alignment: .trailing, spacing: 10) {
                    if let t = trend {
                        HStack(spacing: 4) {
                            Image(systemName: t >= 0 ? "arrow.up.right" : "arrow.down.right")
                                .font(.caption2.weight(.bold))
                            Text("\(String(format: "%.0f", abs(t)))% vs mese scorso")
                                .font(.caption2.weight(.medium))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(.white.opacity(0.15)))
                        .foregroundColor(t <= 0
                            ? Color(red: 0.45, green: 1.0, blue: 0.65)
                            : Color(red: 1.0,  green: 0.5, blue: 0.5))
                    }

                    HStack(spacing: 28) {
                        statColumn(label: "Anno", value: totaleAnno)
                        statColumn(label: "Media mese", value: mediaMensile)
                    }
                }
            }

            // Sparkline andamento giornaliero del mese
            if dailyTotals.count >= 2 {
                Spacer().frame(height: 18)
                sparkline
                    .frame(height: 50)
            }
        }
        .padding(24)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.33, green: 0.24, blue: 0.86),  // indigo
                    Color(red: 0.55, green: 0.18, blue: 0.78)   // viola
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .shadow(color: Color.indigo.opacity(0.35), radius: 14, x: 0, y: 7)
    }

    // MARK: - Subviews

    private func statColumn(label: String, value: Double) -> some View {
        VStack(alignment: .trailing, spacing: 1) {
            Text("€\(String(format: "%.0f", value))")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.white)
            Text(label)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.6))
        }
    }

    private var sparkline: some View {
        Chart(dailyTotals, id: \.date) { item in
            AreaMark(
                x: .value("Giorno", item.date),
                y: .value("Spesa", item.amount)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [.white.opacity(0.5), .white.opacity(0.0)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .interpolationMethod(.catmullRom)

            LineMark(
                x: .value("Giorno", item.date),
                y: .value("Spesa", item.amount)
            )
            .foregroundStyle(.white.opacity(0.85))
            .lineStyle(StrokeStyle(lineWidth: 2))
            .interpolationMethod(.catmullRom)
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartPlotStyle { plot in
            plot.frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Preview
struct HeaderCard_Previews: PreviewProvider {
    static var previews: some View {
        let calendar = Calendar.current
        let now = Date()
        let mockDaily: [(Date, Double)] = (0..<25).reversed().map { i in
            let d = calendar.date(byAdding: .day, value: -i, to: now) ?? now
            let v = Double.random(in: 5...80)
            return (d, v)
        }
        return VStack(spacing: 20) {
            HeaderCard(
                totaleMensile: 1247.30,
                totaleAnno: 8420.00,
                totaleMesePrecedente: 1085.00,
                mediaMensile: 1054.00,
                dailyTotals: mockDaily
            )
            HeaderCard(
                totaleMensile: 750.00,
                totaleAnno: 8420.00,
                totaleMesePrecedente: 1085.00,
                mediaMensile: 1054.00,
                dailyTotals: mockDaily
            )
        }
        .padding()
        .background(Color.systemGroupedBackground)
    }
}
