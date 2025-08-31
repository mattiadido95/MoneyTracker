//
//  HeaderCard.swift
//  MoneyTracker
//
//  Created by Mattia Di Donato on 31/08/25.
//

import SwiftUI

struct HeaderCard: View {
    let totaleMensile: Double
    let totaleAnno: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Benvenuto!")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("€\(String(format: "%.2f", totaleMensile))")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("Spese questo mese")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chart.pie.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.blue)
                    .background(
                        Circle()
                            .fill(Color.blue.opacity(0.1))
                            .frame(width: 70, height: 70)
                    )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
}
