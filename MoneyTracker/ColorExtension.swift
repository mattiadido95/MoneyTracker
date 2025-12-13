//
//  ColorExtension.swift
//  MoneyTracker
//
//  Created by Assistant on 13/12/25.
//

/*
 UTILITY - Color Extension (Estensione Colori Multi-Platform)
 
 Questa estensione fornisce colori di sistema compatibili con iOS e macOS.
 
 PROBLEMA RISOLTO:
 • iOS usa UIColor.systemBackground
 • macOS usa NSColor.windowBackgroundColor
 • Questa estensione unifica l'accesso a questi colori
 
 CONCETTI SWIFT UTILIZZATI:
 • Extension: Aggiunge funzionalità a tipi esistenti
 • Static properties: Proprietà accessibili senza istanza
 • Compilation conditions: #if os() per codice platform-specific
 • Color bridging: SwiftUI Color da UIColor/NSColor
 
 UTILIZZO:
 ```swift
 // Invece di:
 Color(.systemBackground)  // ❌ Errore su macOS
 
 // Usa:
 Color.systemBackground    // ✅ Funziona ovunque
 Color.systemGroupedBackground
 Color.secondarySystemBackground
 ```
 
 DESIGN PATTERN:
 - Cross-platform compatibility
 - Static API design
 - Extension methods
*/

import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

extension Color {
    /// Colore di sfondo principale del sistema (adattivo a Dark Mode)
    static var systemBackground: Color {
        #if os(iOS)
        return Color(uiColor: .systemBackground)
        #elseif os(macOS)
        return Color(nsColor: .windowBackgroundColor)
        #else
        return Color.white
        #endif
    }
    
    /// Colore di sfondo secondario (per contenuti embedded)
    static var secondarySystemBackground: Color {
        #if os(iOS)
        return Color(uiColor: .secondarySystemBackground)
        #elseif os(macOS)
        return Color(nsColor: .controlBackgroundColor)
        #else
        return Color.gray.opacity(0.1)
        #endif
    }
    
    /// Colore di sfondo per liste grouped (iOS style)
    static var systemGroupedBackground: Color {
        #if os(iOS)
        return Color(uiColor: .systemGroupedBackground)
        #elseif os(macOS)
        return Color(nsColor: .windowBackgroundColor).opacity(0.95)
        #else
        return Color.gray.opacity(0.05)
        #endif
    }
    
    /// Colore di sfondo secondario per liste grouped
    static var secondarySystemGroupedBackground: Color {
        #if os(iOS)
        return Color(uiColor: .secondarySystemGroupedBackground)
        #elseif os(macOS)
        return Color(nsColor: .controlBackgroundColor)
        #else
        return Color.gray.opacity(0.1)
        #endif
    }
    
    /// Colore di label principale (testo)
    static var label: Color {
        #if os(iOS)
        return Color(uiColor: .label)
        #elseif os(macOS)
        return Color(nsColor: .labelColor)
        #else
        return Color.primary
        #endif
    }
    
    /// Colore di label secondario (testo meno enfatizzato)
    static var secondaryLabel: Color {
        #if os(iOS)
        return Color(uiColor: .secondaryLabel)
        #elseif os(macOS)
        return Color(nsColor: .secondaryLabelColor)
        #else
        return Color.secondary
        #endif
    }
}
