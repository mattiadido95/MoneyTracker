//
//  AddExpenseView.swift
//  MoneyTracker
//
//  Created by Mattia Di Donato on 07/12/25.
//

import SwiftUI

/// View riutilizzabile per aggiungere o modificare una spesa.
///
/// **Modalità Aggiunta:** `AddExpenseView()` — campi vuoti, titolo "Nuova Spesa"
/// **Modalità Modifica:** `AddExpenseView(spesaDaModificare: spesa)` — campi pre-compilati, titolo "Modifica Spesa"
struct AddExpenseView: View {

    // MARK: - Environment

    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var expenseManager: ExpenseManager

    // MARK: - Modalità

    /// Se presente, la view è in modalità modifica
    private let spesaDaModificare: CategoriaSpesa?
    private var isEditing: Bool { spesaDaModificare != nil }

    // MARK: - State

    @State private var nome = ""
    @State private var importoText = ""
    @State private var selectedColor = Color.blue
    @State private var data = Date()
    @FocusState private var isFocused: Bool

    // MARK: - Init

    init() {
        self.spesaDaModificare = nil
    }

    init(spesaDaModificare: CategoriaSpesa) {
        self.spesaDaModificare = spesaDaModificare
    }

    // MARK: - Computed Properties

    private var isFormValid: Bool {
        !nome.trimmingCharacters(in: .whitespaces).isEmpty && importoDouble != nil
    }

    private var importoDouble: Double? {
        let formatter = NumberFormatter()
        formatter.decimalSeparator = "."
        formatter.numberStyle = .decimal
        if let number = formatter.number(from: importoText) {
            return number.doubleValue
        }
        formatter.decimalSeparator = ","
        if let number = formatter.number(from: importoText) {
            return number.doubleValue
        }
        return nil
    }

    // MARK: - Body

    var body: some View {
        NavigationView {
            #if os(macOS)
            HStack(spacing: 0) {
                Spacer()
                formContent
                    .frame(width: 550)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            #else
            formContent
            #endif
        }
        #if os(macOS)
        .frame(width: 750, height: 650)
        #endif
        .onAppear {
            if let spesa = spesaDaModificare {
                nome = spesa.nome
                importoText = String(format: "%.2f", spesa.importo)
                selectedColor = spesa.colore
                data = spesa.data
            }
        }
    }

    // MARK: - Form Content

    @ViewBuilder
    private var formContent: some View {
        Form {
            Section(header: Text("Informazioni Spesa")) {
                TextField("Nome categoria (es: Luce)", text: $nome)
                    .focused($isFocused)

                HStack {
                    Text("€")
                        .foregroundColor(.secondary)
                    TextField("Importo (es: 89.50)", text: $importoText)
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                        .focused($isFocused)
                }

                if let importo = importoDouble {
                    Text("Importo: €\(String(format: "%.2f", importo))")
                        .font(.caption)
                        .foregroundColor(.green)
                } else if !importoText.isEmpty {
                    Text("Importo non valido")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }

            Section(header: Text("Data e Aspetto")) {
                DatePicker("Data", selection: $data, displayedComponents: .date)
                ColorPicker("Colore categoria", selection: $selectedColor)
                HStack {
                    Text("Anteprima")
                        .foregroundColor(.secondary)
                    Spacer()
                    RoundedRectangle(cornerRadius: 8)
                        .fill(selectedColor)
                        .frame(width: 50, height: 30)
                }
            }

            Section {
                Button(action: salvaSpesa) {
                    HStack {
                        Spacer()
                        Text(isEditing ? "Aggiorna Spesa" : "Salva Spesa")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                }
                .disabled(!isFormValid)
            }
        }
        .navigationTitle(isEditing ? "Modifica Spesa" : "Nuova Spesa")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #elseif os(macOS)
        .formStyle(.grouped)
        #endif
        .toolbar {
            #if os(iOS)
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Annulla") { dismiss() }
            }
            #else
            ToolbarItem(placement: .cancellationAction) {
                Button("Annulla") { dismiss() }
            }
            #endif
            #if os(iOS)
            ToolbarItem(placement: .keyboard) {
                Button("Fine") { isFocused = false }
            }
            #endif
        }
    }

    // MARK: - Methods

    private func salvaSpesa() {
        guard let importo = importoDouble else { return }

        if let spesaOriginale = spesaDaModificare {
            let spesaAggiornata = CategoriaSpesa(
                id: spesaOriginale.id,
                nome: nome.trimmingCharacters(in: .whitespaces),
                importo: importo,
                colore: selectedColor,
                data: data
            )
            expenseManager.aggiornaSpesa(spesaAggiornata)
        } else {
            let nuovaSpesa = CategoriaSpesa(
                nome: nome.trimmingCharacters(in: .whitespaces),
                importo: importo,
                colore: selectedColor,
                data: data
            )
            expenseManager.aggiungiSpesa(nuovaSpesa)
        }
        dismiss()
    }
}

// MARK: - Preview
struct AddExpenseView_Previews: PreviewProvider {
    static var previews: some View {
        AddExpenseView()
            .environmentObject(ExpenseManager(mockData: true))
    }
}
