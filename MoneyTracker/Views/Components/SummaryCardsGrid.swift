//
//  SummaryCardsGrid.swift
//  MoneyTracker
//
//  Created by Mattia Di Donato on 31/08/25.
//

import SwiftUI

struct SummaryCardsGrid: View {
    let totaleAnno: Double
    let prossimaScadenza: String
    let numeroBolletteMese: Int
    let mediaMensile: Double
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            
            SummaryCard(
                title: "Totale Anno",
                value: "€\(String(format: "%.2f", totaleAnno))",
                icon: "calendar",
                color: .green
            )
            
            SummaryCard(
                title: "Prossima Scadenza",
                value: prossimaScadenza,
                icon: "clock.fill",
                color: .orange
            )
            
            SummaryCard(
                title: "Bollette Mese",
                value: "\(numeroBolletteMese)",
                icon: "doc.text.fill",
                color: .purple
            )
            
            SummaryCard(
                title: "Media Mensile",
                value: "€\(String(format: "%.2f", mediaMensile))",
                icon: "chart.line.uptrend.xyaxis",
                color: .indigo
            )
        }
    }
}
