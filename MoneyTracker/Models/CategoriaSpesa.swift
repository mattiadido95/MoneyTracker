//
//  CategoriaSpesa.swift
//  MoneyTracker
//
//  Created by Mattia Di Donato on 31/08/25.
//

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
