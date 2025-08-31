//
//  CategoryRow.swift
//  MoneyTracker
//
//  Created by Mattia Di Donato on 31/08/25.
//

import SwiftUI

struct CategoryRow: View {
    let categoria: CategoriaSpesa
    let totale: Double
    
    var percentuale: Double {
        (categoria.importo / totale) * 100
    }
    
    var body: some View {
        HStack {
            RoundedRectangle(cornerRadius: 2)
                .fill(categoria.colore)
                .frame(width: 4, height: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(categoria.nome)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("\(String(format: "%.1f", percentuale))% del totale")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("€\(String(format: "%.2f", categoria.importo))")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(categoria.colore)
        }
        .padding(.vertical, 4)
    }
}
