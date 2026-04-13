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

#if os(iOS)
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
#elseif os(macOS)
import AppKit

/// Su macOS usiamo NSSharingServicePicker per condividere file.
/// Mostra un pulsante "Condividi" che apre il picker nativo di macOS.
struct ActivityViewController: View {
    let activityItems: [Any]
    let onComplete: (() -> Void)?

    init(activityItems: [Any], onComplete: (() -> Void)? = nil) {
        self.activityItems = activityItems
        self.onComplete = onComplete
    }

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "square.and.arrow.up")
                .font(.system(size: 40))
                .foregroundColor(.accentColor)

            Text("Condividi file esportato")
                .font(.headline)

            // Mostra il path del file se è un URL
            if let url = activityItems.first as? URL {
                Text(url.lastPathComponent)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 12) {
                // Pulsante condividi tramite NSSharingServicePicker
                Button("Condividi...") {
                    showSharingPicker()
                }
                .buttonStyle(.borderedProminent)

                // Pulsante per mostrare nel Finder
                if let url = activityItems.first as? URL {
                    Button("Mostra nel Finder") {
                        NSWorkspace.shared.selectFile(
                            url.path,
                            inFileViewerRootedAtPath: url.deletingLastPathComponent().path
                        )
                        onComplete?()
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding(40)
        .frame(minWidth: 350)
    }

    /// Apre il NSSharingServicePicker nativo di macOS ancorato alla finestra corrente
    private func showSharingPicker() {
        let picker = NSSharingServicePicker(items: activityItems)
        // Trova la finestra corrente per ancorare il picker
        if let window = NSApp.keyWindow,
           let contentView = window.contentView {
            picker.show(
                relativeTo: contentView.bounds,
                of: contentView,
                preferredEdge: .minY
            )
        }
        onComplete?()
    }
}
#endif

