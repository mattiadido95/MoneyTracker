//
//  DocumentPicker.swift
//  MoneyTracker
//
//  Created by Assistant on 13/12/25.
//

/*
 UI HELPER - DocumentPicker (Selezionatore File)
 
 Questo è un wrapper SwiftUI per UIDocumentPickerViewController (UIKit).
 Permette all'utente di selezionare file JSON dal file system.
 
 CONCETTI UTILIZZATI:
 • UIViewControllerRepresentable: Bridge UIKit → SwiftUI
 • Coordinator pattern: Gestisce i delegate di UIKit
 • Closures: Callback quando l'utente seleziona un file
 • File picker: Interfaccia nativa iOS per selezionare file
 
 FUNZIONALITÀ:
 - Mostra il picker nativo di iOS per selezionare file
 - Filtra solo file JSON (UTType.json)
 - Chiama un callback quando l'utente seleziona un file
 - Si chiude automaticamente dopo la selezione
 
 UTILIZZO:
 ```swift
 @State private var showingPicker = false
 
 .sheet(isPresented: $showingPicker) {
     DocumentPicker(isPresented: $showingPicker) { fileURL in
         // Gestisci il file selezionato
         handleImport(from: fileURL)
     }
 }
 ```
*/

import SwiftUI
import UniformTypeIdentifiers

struct DocumentPicker: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    let onFilePicked: (URL) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        // Crea il picker per file JSON
        let picker = UIDocumentPickerViewController(
            forOpeningContentTypes: [.json],  // Solo file JSON
            asCopy: true  // Copia il file (non lo sposta)
        )
        
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false  // Solo un file alla volta
        
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {
        // Non serve aggiornare nulla
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    // MARK: - Coordinator
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker
        
        init(parent: DocumentPicker) {
            self.parent = parent
        }
        
        // Chiamato quando l'utente seleziona un file
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let fileURL = urls.first else { return }
            
            print("📁 File selezionato: \(fileURL.lastPathComponent)")
            
            // Chiama il callback
            parent.onFilePicked(fileURL)
            
            // Chiudi il picker
            parent.isPresented = false
        }
        
        // Chiamato quando l'utente annulla
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            print("❌ Selezione file annullata")
            parent.isPresented = false
        }
    }
}
