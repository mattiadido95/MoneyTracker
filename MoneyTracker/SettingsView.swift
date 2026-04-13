//
//  SettingsView.swift
//  MoneyTracker
//
//  Created by Mattia Di Donato on 13/04/26.
//

import SwiftUI

/// Schermata impostazioni dell'app.
///
/// Usa `@AppStorage` per persistere le preferenze in `UserDefaults`
/// automaticamente, senza dover gestire save/load manualmente.
///
/// **Impostazioni disponibili:**
/// - Tema: chiaro, scuro, o automatico (segue il sistema)
/// - Valuta di default per la visualizzazione importi
/// - Informazioni app e link utili
struct SettingsView: View {

    // MARK: - AppStorage (persistenza automatica in UserDefaults)

    /// Tema selezionato dall'utente: "system", "light" o "dark"
    @AppStorage("appTheme") private var appTheme: String = "system"

    /// Simbolo valuta per la visualizzazione (default: €)
    @AppStorage("currencySymbol") private var currencySymbol: String = "€"

    // MARK: - Environment

    @Environment(\.dismiss) var dismiss

    // MARK: - Body

    var body: some View {
        Form {
            // Sezione aspetto
            Section {
                Picker("Tema", selection: $appTheme) {
                    Label("Automatico", systemImage: "circle.lefthalf.filled")
                        .tag("system")
                    Label("Chiaro", systemImage: "sun.max.fill")
                        .tag("light")
                    Label("Scuro", systemImage: "moon.fill")
                        .tag("dark")
                }
                #if os(iOS)
                .pickerStyle(.inline)
                #endif
            } header: {
                Text("Aspetto")
            } footer: {
                Text("\"Automatico\" segue le impostazioni del dispositivo.")
            }

            // Sezione valuta
            Section {
                Picker("Valuta", selection: $currencySymbol) {
                    Text("€ Euro").tag("€")
                    Text("$ Dollaro").tag("$")
                    Text("£ Sterlina").tag("£")
                    Text("CHF Franco").tag("CHF")
                }
            } header: {
                Text("Valuta")
            } footer: {
                Text("Simbolo visualizzato accanto agli importi.")
            }

            // Sezione info app
            Section("Informazioni") {
                HStack {
                    Text("Versione")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Sviluppatore")
                    Spacer()
                    Text("Mattia Di Donato")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Impostazioni")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #elseif os(macOS)
        .formStyle(.grouped)
        #endif
    }

    // MARK: - Helpers

    /// Converte la stringa del tema in `ColorScheme` per il modifier `.preferredColorScheme()`
    /// Restituisce nil per "system" (segue il dispositivo)
    static func colorScheme(from theme: String) -> ColorScheme? {
        switch theme {
        case "light": return .light
        case "dark": return .dark
        default: return nil  // "system" → segue il dispositivo
        }
    }
}

// MARK: - Preview

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SettingsView()
        }
    }
}
