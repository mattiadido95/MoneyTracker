//
//  AddExpenseButton.swift
//  MoneyTracker
//
//  Created by Mattia Di Donato on 31/08/25.
//

/*
 COMPONENTE UI - AddExpenseButton (Pulsante Aggiungi Spesa)
 
 Questo è un pulsante Call-To-Action (CTA) principale per aggiungere nuove spese.
 È progettato per essere visivamente prominente e invitare all'azione.
 
 CONCETTI SWIFT/SWIFTUI UTILIZZATI:
 • Closure parameters: `let action: () -> Void` - funzione passata come parametro
 • Button con action personalizzata: Pulsante che esegue codice esterno
 • LinearGradient: Sfumatura lineare per effetti visivi accattivanti
 • startPoint/endPoint: Controllo della direzione del gradiente
 • PlainButtonStyle(): Rimuove lo stile default di iOS per controllo completo
 • Shadow con colore personalizzato: Ombra colorata per effetto "glow"
 • Opacity modifiers: .opacity() per trasparenza parziale
 • Foreground color unificato: Tutto il contenuto in bianco per contrasto
 
 FUNZIONALITÀ:
 - Pulsante principale per iniziare il flusso di aggiunta spese
 - Design accattivante con gradiente blu e ombra colorata
 - Layout orizzontale con icona, testo e freccia
 - Feedback visivo attraverso ombre e colori
 
 DESIGN PRINCIPLES:
 - Primary Action: Colore blu prominente indica l'azione principale
 - Visual Hierarchy: Il gradiente e l'ombra lo rendono il focus principale
 - Iconografia chiara: Plus icon = aggiungere, chevron = navigazione
 - Consistency: Usa la stessa palette di colori dell'app
 
 STATO ATTUALE:
 - Funzionalità: Solo l'aspetto visivo è completo
 - L'azione viene passata dall'esterno ma stampa solo un messaggio
 - Manca la navigazione verso la schermata di aggiunta
 
 UTILIZZO NEL PROGETTO:
 - Utilizzato da HomeView come elemento prominente della dashboard
 - Riceve la funzione da eseguire come parametro (dependency injection)
 - Sarà collegato alla futura schermata di inserimento spese
 
 DESIGN PATTERN:
 - Callback Pattern: Il pulsante non sa cosa fare, glielo dice chi lo usa
 - Visual Prominence: Design che attira l'attenzione sull'azione principale
*/

import SwiftUI

struct AddExpenseButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                
                Text("Aggiungi Nuova Spesa")
                    .font(.headline)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            .foregroundColor(.white)
            .padding()
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [.blue, .blue.opacity(0.8)]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
            .shadow(color: .blue.opacity(0.3), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
