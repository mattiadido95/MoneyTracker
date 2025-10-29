//
//  SummaryCard.swift
//  MoneyTracker
//
//  Created by Mattia Di Donato on 31/08/25.
//

/*
 COMPONENTE UI - SummaryCard (Card Riassuntiva)
 
 Questo è un componente UI riutilizzabile che crea delle "card" informative
 per mostrare statistiche e metriche chiave nella dashboard.
 
 CONCETTI SWIFT/SWIFTUI UTILIZZATI:
 • Parametric design: Il componente accetta parametri per essere completamente personalizzabile
 • Image(systemName:): Uso delle icone di sistema di Apple (SF Symbols)
 • Text modifiers avanzati: .lineLimit(), .minimumScaleFactor() per gestire testi lunghi
 • Frame con alignment: .maxWidth + .leading per layout flessibile ma controllato
 • LinearGradient: Sfumature per effetti visivi sofisticati (non usato qui ma disponibile)
 • Shadow system: Ombreggiature sottili per profondità visiva
 • Color(.systemBackground): Colori adattivi che cambiano con Dark/Light mode
 
 FUNZIONALITÀ:
 - Visualizza un'icona colorata nell'angolo superiore sinistro
 - Mostra un valore principale (numero, testo) in evidenza
 - Include un titolo descrittivo sotto il valore
 - Si adatta automaticamente ai contenuti lunghi (testo che non entra)
 - Fornisce uno stile uniforme per tutte le metriche
 
 DESIGN INTELLIGENTE:
 - .minimumScaleFactor(0.8): Se il testo è troppo lungo, lo riduce fino all'80%
 - .lineLimit(1) per il valore: Forza su una riga per consistenza visiva
 - .lineLimit(2) per il titolo: Permette massimo 2 righe per descrizioni lunghe
 - Colori dinamici che si adattano al tema del sistema
 
 UTILIZZO NEL PROGETTO:
 - Utilizzato da SummaryCardsGrid per creare la griglia di 4 metriche
 - Ogni card mostra una statistica diversa (totale anno, scadenze, etc.)
 - Completamente riutilizzabile: basta cambiare i parametri
 
 DESIGN PATTERN:
 - Reusable Component: Stesso codice, aspetti diversi tramite parametri
 - Adaptive Design: Si adatta automaticamente a contenuti e tema del sistema
*/

import SwiftUI

struct SummaryCard: View {
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
                .font(.headline)
                .fontWeight(.semibold)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
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
