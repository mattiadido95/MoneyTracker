//
//  ActivityViewController.swift
//  MoneyTracker
//
//  Created by Assistant on 13/12/25.
//

/*
 UI HELPER - ActivityViewController (Share Sheet)
 
 Questo è un wrapper SwiftUI per UIActivityViewController (UIKit).
 Permette di condividere file con altre app (AirDrop, Files, Mail, etc.).
 
 CONCETTI UTILIZZATI:
 • UIViewControllerRepresentable: Bridge UIKit → SwiftUI
 • Share sheet: Interfaccia nativa iOS per condividere contenuti
 • Completion handler: Callback quando la condivisione è completata
 • Activity items: Qualsiasi oggetto condivisibile (URL, String, Image, etc.)
 
 FUNZIONALITÀ:
 - Mostra lo share sheet nativo di iOS
 - Permette di salvare su Files, inviare via AirDrop, Mail, etc.
 - Notifica quando la condivisione è completata
 - Si chiude automaticamente dopo l'azione
 
 UTILIZZO:
 ```swift
 @State private var showingShareSheet = false
 @State private var fileURL: URL?
 
 .sheet(isPresented: $showingShareSheet) {
     if let fileURL = fileURL {
         ActivityViewController(activityItems: [fileURL]) {
             print("Condivisione completata!")
         }
     }
 }
 ```
*/

import SwiftUI
import UIKit

struct ActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]
    let onComplete: (() -> Void)?
    
    init(activityItems: [Any], onComplete: (() -> Void)? = nil) {
        self.activityItems = activityItems
        self.onComplete = onComplete
    }
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        
        // Completion handler
        controller.completionWithItemsHandler = { activityType, completed, returnedItems, error in
            if let error = error {
                print("❌ Errore nella condivisione: \(error.localizedDescription)")
                return
            }
            
            if completed {
                print("✅ Condivisione completata: \(activityType?.rawValue ?? "sconosciuto")")
                context.coordinator.onComplete?()
            } else {
                print("❌ Condivisione annullata")
            }
        }
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // Non serve aggiornare nulla
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onComplete: onComplete)
    }
    
    // MARK: - Coordinator
    
    class Coordinator {
        let onComplete: (() -> Void)?
        
        init(onComplete: (() -> Void)?) {
            self.onComplete = onComplete
        }
    }
}
