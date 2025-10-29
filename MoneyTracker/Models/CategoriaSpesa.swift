//
//  CategoriaSpesa.swift
//  MoneyTracker
//
//  Created by Mattia Di Donato on 31/08/25.
//

/*
 MODELLO DATI - CategoriaSpesa
 
 Questo file definisce la struttura dati fondamentale per rappresentare una categoria di spesa.
 
 CONCETTI SWIFT UTILIZZATI:
 • struct: Tipo di valore (value type) - quando assegni una struct a un'altra variabile, 
   viene creata una copia completa
 • let: Proprietà immutabili - una volta assegnate non possono essere modificate
 • init: Costruttore personalizzato per inizializzare le proprietà della struct
 • SwiftUI.Color: Tipo specifico di SwiftUI per gestire i colori nell'interfaccia
 
 FUNZIONALITÀ:
 - Rappresenta una singola categoria di spesa (es: Luce, Gas, Acqua)
 - Memorizza nome, importo e colore associato per l'identificazione visiva
 - Utilizzata in tutta l'app per organizzare e visualizzare le spese per categoria
 
 UTILIZZO NEL PROGETTO:
 - ExpenseManager la usa negli array per memorizzare le categorie
 - CategoryRow la usa per visualizzare ogni singola riga nella lista
 - I colori vengono usati per creare elementi grafici distintivi nell'UI
*/

import SwiftUI

struct CategoriaSpesa {
    let nome: String
    let importo: Double
    let colore: SwiftUI.Color
    
    init(nome: String, importo: Double, colore: SwiftUI.Color) {
        self.nome = nome
        self.importo = importo
        self.colore = colore
    }
}
