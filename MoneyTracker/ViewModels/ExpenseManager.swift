//
//  ExpenseManager.swift
//  MoneyTracker
//
//  Created by Mattia Di Donato on 31/08/25.
//

import SwiftUI
import Combine

class ExpenseManager: ObservableObject {
    @Published var totaleMensile: Double = 1250.50
    @Published var totaleAnno: Double = 12890.75
    @Published var prossimaScadenza = "Luce - 15 Gen"
    @Published var numeroBolletteMese: Int = 8
    @Published var mediaMensile: Double = 1074.23
    
    @Published var categorieSpese = [
        CategoriaSpesa(nome: "Luce", importo: 89.50, colore: Color.yellow),
        CategoriaSpesa(nome: "Gas", importo: 156.20, colore: Color.blue),
        CategoriaSpesa(nome: "Acqua", importo: 45.80, colore: Color.cyan),
        CategoriaSpesa(nome: "Internet", importo: 29.90, colore: Color.purple),
        CategoriaSpesa(nome: "Tari", importo: 400.90, colore: Color.red)
    ]
    
    func aggiungiSpesa(_ spesa: CategoriaSpesa) {
        // Logica per aggiungere una nuova spesa
        categorieSpese.append(spesa)
        calcolaTotali()
    }
    
    private func calcolaTotali() {
        totaleMensile = categorieSpese.reduce(0) { $0 + $1.importo }
        // Altri calcoli...
    }
}
