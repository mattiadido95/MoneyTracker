//
//  CategoriesSection.swift
//  MoneyTracker
//
//  Created by Mattia Di Donato on 31/08/25.
//

import SwiftUI

struct CategoriesSection: View {
    let categorie: [CategoriaSpesa]
    let totaleMensile: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Categorie Questo Mese")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Vedi Tutto") {
                    print("Vedi tutto categorie tapped")
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            VStack(spacing: 8) {
                ForEach(categorie, id: \.nome) { categoria in
                    CategoryRow(categoria: categoria, totale: totaleMensile)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
            )
        }
    }
}
