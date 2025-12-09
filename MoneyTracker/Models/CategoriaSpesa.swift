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
 • Codable: Protocollo che permette serializzazione automatica in JSON
 • Identifiable: Protocollo che richiede un id univoco per SwiftUI lists
 • UUID: Identificatore univoco universale per ogni spesa
 • Date: Timestamp per tracciare quando è stata registrata la spesa
 • Computed property: colore viene calcolato da coloreNome
 • Extension: Aggiunge funzionalità a Color per conversione String
 
 FUNZIONALITÀ:
 - Rappresenta una singola categoria di spesa (es: Luce, Gas, Acqua)
 - Memorizza nome, importo, colore e data
 - Serializzabile in JSON per persistenza
 - Identificabile univocamente per SwiftUI
 
 UTILIZZO NEL PROGETTO:
 - ExpenseManager la usa negli array per memorizzare le categorie
 - CategoryRow la usa per visualizzare ogni singola riga nella lista
 - PersistenceManager la salva/carica da JSON
*/

import SwiftUI

struct CategoriaSpesa: Codable, Identifiable {
    let id: UUID
    let nome: String
    let importo: Double
    let data: Date
    
    // Colore serializzato come stringa (es: "blue", "red")
    // I Color non possono essere serializzati direttamente in JSON
    private let coloreNome: String
    
    // Computed property per ottenere il Color SwiftUI
    var colore: Color {
        get { Color.fromString(coloreNome) }
    }
    
    init(id: UUID = UUID(), nome: String, importo: Double, colore: Color, data: Date = Date()) {
        self.id = id
        self.nome = nome
        self.importo = importo
        self.coloreNome = colore.toString()
        self.data = data
    }
    
    // CodingKeys per serializzazione JSON
    enum CodingKeys: String, CodingKey {
        case id, nome, importo, data, coloreNome
    }
}

// MARK: - Color Extension per serializzazione

extension Color {
    /// Converte Color in String per salvataggio JSON
    func toString() -> String {
        switch self {
        case .red: return "red"
        case .blue: return "blue"
        case .green: return "green"
        case .yellow: return "yellow"
        case .orange: return "orange"
        case .purple: return "purple"
        case .pink: return "pink"
        case .cyan: return "cyan"
        case .indigo: return "indigo"
        default: return "blue" // fallback
        }
    }
    
    /// Converte String in Color per caricamento JSON
    static func fromString(_ string: String) -> Color {
        switch string.lowercased() {
        case "red": return .red
        case "blue": return .blue
        case "green": return .green
        case "yellow": return .yellow
        case "orange": return .orange
        case "purple": return .purple
        case "pink": return .pink
        case "cyan": return .cyan
        case "indigo": return .indigo
        default: return .blue
        }
    }
}
