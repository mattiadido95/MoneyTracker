//
//  CategoryRow.swift
//  MoneyTracker
//
//  Created by Mattia Di Donato on 31/08/25.
//

/*
 COMPONENTE UI - CategoryRow (Riga Singola Categoria)
 
 Questo componente rappresenta una singola riga nella lista delle categorie di spesa.
 È il livello più granulare della visualizzazione categorie.
 
 CONCETTI SWIFT/SWIFTUI UTILIZZATI:
 • computed property (percentuale): Proprietà calcolata che si aggiorna automaticamente
   quando cambiano i valori da cui dipende (categoria.importo o totale)
 • String formatting: String(format: "%.1f", valore) per controllare i decimali mostrati
 • Color system: Uso dinamico dei colori delle categorie per coerenza visiva
 • Spacer(): Elemento flessibile che occupa tutto lo spazio disponibile
 • VStack con alignment: .leading: Stack verticale allineato a sinistra
 • Font system: Uso della tipografia di sistema (.subheadline, .caption2)
 • Padding: .vertical per spaziatura solo sopra/sotto
 
 FUNZIONALITÀ:
 - Mostra un indicatore colorato sulla sinistra (barra verticale)
 - Visualizza nome categoria e percentuale rispetto al totale
 - Mostra l'importo formattato con il colore della categoria
 - Calcola automaticamente la percentuale quando cambiano i valori
 
 LOGICA DI BUSINESS:
 - La percentuale viene calcolata: (importo categoria / totale mensile) × 100
 - I colori sono coerenti: stesso colore per indicatore e importo
 - Formatting intelligente: 1 decimale per %, 2 decimali per importi
 
 UTILIZZO NEL PROGETTO:
 - Utilizzato da CategoriesSection in un ForEach
 - Riceve una CategoriaSpesa e il totale come parametri
 - Rappresenta l'elemento più piccolo e riutilizzabile del sistema categorie
 
 DESIGN PATTERN:
 - Single Responsibility: si occupa SOLO di visualizzare una singola categoria
 - Data-driven: tutto il contenuto deriva dai dati passati come parametri
*/

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
