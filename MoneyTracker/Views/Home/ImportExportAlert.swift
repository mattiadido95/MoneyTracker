//
//  ImportExportAlert.swift
//  MoneyTracker
//
//  Created by Assistant on 13/12/25.
//

/*
 UI HELPER - ImportExportAlert (Alert per Import/Export)
 
 Questo è un helper per mostrare alert di successo o errore
 durante le operazioni di import/export.
 
 CONCETTI UTILIZZATI:
 • Identifiable: Permette di usare .alert(item:)
 • Factory methods: .success() e .error() per creare alert facilmente
 • Static methods: Metodi di convenienza per creare istanze
 
 FUNZIONALITÀ:
 - Mostra alert di successo con icona ✅
 - Mostra alert di errore con icona ❌
 - Identifiable per SwiftUI alert binding
 - Factory methods per creazione semplificata
 
 UTILIZZO:
 ```swift
 @State private var alertItem: ImportExportAlert?
 
 // Successo
 alertItem = .success("Operazione completata!")
 
 // Errore
 alertItem = .error("Qualcosa è andato storto")
 
 // In SwiftUI
 .alert(item: $alertItem) { alert in
     Alert(
         title: Text(alert.title),
         message: Text(alert.message),
         dismissButton: .default(Text("OK"))
     )
 }
 ```
*/

import Foundation

struct ImportExportAlert: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let isError: Bool
    
    /// Crea un alert di successo
    /// - Parameter message: Messaggio da mostrare
    /// - Returns: Alert configurato per successo
    static func success(_ message: String) -> ImportExportAlert {
        ImportExportAlert(
            title: "✅ Successo",
            message: message,
            isError: false
        )
    }
    
    /// Crea un alert di errore
    /// - Parameter message: Messaggio di errore da mostrare
    /// - Returns: Alert configurato per errore
    static func error(_ message: String) -> ImportExportAlert {
        ImportExportAlert(
            title: "❌ Errore",
            message: message,
            isError: true
        )
    }
}
