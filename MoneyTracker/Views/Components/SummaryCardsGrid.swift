//
//  SummaryCardsGrid.swift
//  MoneyTracker
//
//  Created by Mattia Di Donato on 31/08/25.
//

/*
 COMPONENTE UI - SummaryCardsGrid (Griglia Cards Riassuntive)
 
 Questo componente organizza le SummaryCard in una griglia di 2 colonne,
 creando la sezione delle metriche principali nella dashboard.
 
 CONCETTI SWIFT/SWIFTUI UTILIZZATI:
 • LazyVGrid: Sistema di layout a griglia che crea elementi solo quando necessario
   (lazy = pigro, crea le view solo quando diventano visibili)
 • GridItem(.flexible()): Elementi della griglia che si adattano automaticamente
 • Array di GridItem: Definisce la struttura delle colonne [colonna1, colonna2]
 • spacing: Parametro per controllare la distanza tra gli elementi
 • SF Symbols naming: Convenzioni per i nomi delle icone di sistema Apple
 • Color system: Palette di colori semantici (.green, .orange, .purple, .indigo)
 
 FUNZIONALITÀ:
 - Organizza 4 metriche chiave in una griglia 2x2
 - Layout responsive che si adatta alle dimensioni dello schermo
 - Ogni card mostra una statistica diversa con icona e colore specifici
 - Spaziatura uniforme tra tutti gli elementi
 
 STRUTTURA DATI VISUALIZZATI:
 1. "Totale Anno" - Verde con icona calendario
 2. "Prossima Scadenza" - Arancione con icona orologio  
 3. "Bollette Mese" - Viola con icona documento
 4. "Media Mensile" - Indaco con icona grafico
 
 DESIGN PRINCIPLES:
 - Uso di colori semantici: Verde = positivo, Arancione = attenzione, etc.
 - Icone intuitive che rappresentano chiaramente il contenuto
 - Layout simmetrico per equilibrio visivo
 - Lazy loading per performance ottimali
 
 UTILIZZO NEL PROGETTO:
 - Utilizzato da HomeView come parte centrale della dashboard
 - Riceve tutti i dati da ExpenseManager tramite parametri
 - Usa il componente SummaryCard per renderizzare ogni singola metrica
 
 DESIGN PATTERN:
 - Composition: Compone SummaryCard per creare un layout complesso
 - Data Mapping: Trasforma dati grezzi in elementi UI strutturati
*/

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
