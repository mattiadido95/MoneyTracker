//
//  CategoriesSection.swift
//  MoneyTracker
//
//  Created by Mattia Di Donato on 31/08/25.
//

/*
 COMPONENTE UI - CategoriesSection (Sezione Categorie)
 
 Questo componente visualizza la sezione "Categorie Questo Mese" nella dashboard principale.
 
 CONCETTI SWIFT/SWIFTUI UTILIZZATI:
 • struct che implementa View: Pattern base per tutti i componenti UI in SwiftUI
 • let: Proprietà immutabili passate dal componente padre (HomeView)
 • VStack/HStack: Layout verticali e orizzontali per organizzare gli elementi
 • ForEach: Ciclo per creare elementi UI dinamicamente da un array
 • id: \.nome: Chiave unica per identificare ogni elemento nell'array (necessario per ForEach)
 • Button: Elemento interattivo con azione associata
 • Modifier chains: Serie di modificatori (.font, .padding, etc.) per stilizzare gli elementi
 • RoundedRectangle: Forma geometrica per creare sfondi arrotondati
 • Shadow: Effetto ombra per dare profondità visiva
 
 FUNZIONALITÀ:
 - Mostra il titolo della sezione con pulsante "Vedi Tutto"
 - Elenca tutte le categorie di spesa usando CategoryRow
 - Fornisce uno sfondo stilizzato con ombre per il contenitore
 - Gestisce il layout responsivo degli elementi
 
 STATO ATTUALE:
 - Il pulsante "Vedi Tutto" stampa solo un messaggio (non implementato)
 - La lista viene generata dinamicamente dall'array delle categorie
 
 UTILIZZO NEL PROGETTO:
 - Utilizzato da HomeView come parte della dashboard
 - Riceve i dati da ExpenseManager attraverso le props
 - Ogni categoria viene renderizzata usando CategoryRow
 
 DESIGN PATTERN:
 - Separazione delle responsabilità: questo componente si occupa solo del layout della sezione
 - CategoryRow gestisce la visualizzazione dei singoli elementi
*/

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
