//
//  HeaderCard.swift
//  MoneyTracker
//
//  Created by Mattia Di Donato on 31/08/25.
//

/*
 COMPONENTE UI - HeaderCard (Card di Benvenuto)
 
 Questo è il componente hero della dashboard - la prima cosa che l'utente vede.
 Mostra il messaggio di benvenuto e il totale delle spese mensili in grande evidenza.
 
 CONCETTI SWIFT/SWIFTUI UTILIZZATI:
 • VStack con alignment: Stack verticale allineato a sinistra
 • String formatting avanzato: String(format: "%.2f", valore) per controllo decimali
 • Font system hierarchy: .headline, .system(size:weight:design:), .caption
 • Font design variants: .rounded per numeri più moderni e leggibili
 • Color semantics: .primary, .secondary per adattamento automatico ai temi
 • Circle background: Sfondo circolare per icone con dimensioni fisse
 • Nested HStack/VStack: Layout complessi con stack annidati
 • Shadow system: Ombre sottili per profondità e separazione visiva
 
 FUNZIONALITÀ:
 - Messaggio di benvenuto personalizzato per l'utente
 - Visualizzazione prominente del totale mensile delle spese
 - Icona decorativa con sfondo circolare colorato
 - Design card con bordi arrotondati e ombra
 
 DESIGN HIERARCHY:
 - "Benvenuto!" - Headline secondario per orientamento
 - Importo - Display principale in grande, grassetto e rounded
 - "Spese questo mese" - Caption esplicativo per contesto
 - Icona - Elemento visivo di supporto, non distraente
 
 UX PRINCIPLES:
 - F-Pattern Reading: Informazioni disposte per lettura naturale
 - Visual Weight: Il numero più importante è il più grande e visibile
 - Contextual Information: Ogni dato ha la sua etichetta esplicativa
 - Breathing Room: Spaziatura generosa per non affollare
 
 STATO ATTUALE:
 - Design completo e funzionale
 - Riceve dati da ExpenseManager ma non li modifica
 - Potenziale per aggiungere interazioni future (tap per dettagli)
 
 UTILIZZO NEL PROGETTO:
 - Prima sezione di HomeView, sopra tutto il resto
 - Riceve totaleMensile e totaleAnno da ExpenseManager
 - Attualmente usa solo totaleMensile, ma ha accesso anche al totale annuale
 
 DESIGN PATTERN:
 - Hero Component: Il componente principale che domina visivamente
 - Read-Only Display: Mostra informazioni senza permettere modifiche
*/

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
                .fill(Color.systemBackground)
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
}
