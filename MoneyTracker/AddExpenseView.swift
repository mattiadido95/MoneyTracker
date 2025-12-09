//
//  AddExpenseView.swift
//  MoneyTracker
//
//  Created by Assistant on 07/12/25.
//

/*
 VIEW - AddExpenseView (Schermata Aggiunta Spesa)
 
 Questa schermata permette all'utente di aggiungere una nuova spesa.
 
 CONCETTI SWIFT/SWIFTUI UTILIZZATI:
 • @State: Property wrapper per stato locale della view
 • @Environment(\.dismiss): Modo moderno per chiudere una view modale
 • @EnvironmentObject: Riceve ExpenseManager condiviso
 • Form: Container nativo iOS per form di input
 • TextField: Input di testo
 • DatePicker: Selettore di date nativo
 • ColorPicker: Selettore di colori nativo (iOS 14+)
 • @FocusState: Gestione automatica della tastiera
 • Formatter: NumberFormatter per input decimali corretti
 • Validation: Controllo che i dati siano validi prima di salvare
 • Sheet presentation: View modale che scorre dal basso
 
 FUNZIONALITÀ:
 - Form con campi per nome, importo, data e colore
 - Validazione input (nome non vuoto, importo valido)
 - ColorPicker per scegliere il colore della categoria
 - DatePicker per selezionare la data della spesa
 - Pulsante Salva che aggiunge la spesa e chiude la view
 - Pulsante Annulla nella toolbar
 
 UX DESIGN:
 - Keyboard ottimizzato (.decimalPad per importo)
 - Validazione in tempo reale
 - Feedback visivo (pulsante disabilitato se dati non validi)
 - Dismissal automatico dopo salvataggio
 
 UTILIZZO:
 - Presentata come sheet da HomeView
 - Usa ExpenseManager per salvare i dati
 - Chiude automaticamente dopo il salvataggio
*/

import SwiftUI

struct AddExpenseView: View {
    // MARK: - Environment
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var expenseManager: ExpenseManager
    
    // MARK: - State
    @State private var nome = ""
    @State private var importoText = ""
    @State private var selectedColor = Color.blue
    @State private var data = Date()
    @FocusState private var isFocused: Bool
    
    // MARK: - Computed Properties
    
    /// Verifica se il form è valido
    private var isFormValid: Bool {
        !nome.isEmpty && importoDouble != nil
    }
    
    /// Converte il testo in Double (nil se non valido)
    private var importoDouble: Double? {
        let formatter = NumberFormatter()
        formatter.decimalSeparator = "."
        formatter.numberStyle = .decimal
        
        // Prova con separatore punto
        if let number = formatter.number(from: importoText) {
            return number.doubleValue
        }
        
        // Prova con separatore virgola
        formatter.decimalSeparator = ","
        if let number = formatter.number(from: importoText) {
            return number.doubleValue
        }
        
        return nil
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Informazioni Spesa")) {
                    TextField("Nome categoria (es: Luce)", text: $nome)
                        .focused($isFocused)
                    
                    HStack {
                        Text("€")
                            .foregroundColor(.secondary)
                        TextField("Importo (es: 89.50)", text: $importoText)
                            .keyboardType(.decimalPad)
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
                    DatePicker(
                        "Data",
                        selection: $data,
                        displayedComponents: .date
                    )
                    
                    ColorPicker("Colore categoria", selection: $selectedColor)
                    
                    // Preview del colore
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
                            Text("Salva Spesa")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(!isFormValid)
                }
            }
            .navigationTitle("Nuova Spesa")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annulla") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .keyboard) {
                    Button("Fine") {
                        isFocused = false
                    }
                }
            }
        }
    }
    
    // MARK: - Methods
    
    private func salvaSpesa() {
        guard let importo = importoDouble else { return }
        
        let nuovaSpesa = CategoriaSpesa(
            nome: nome,
            importo: importo,
            colore: selectedColor,
            data: data
        )
        
        expenseManager.aggiungiSpesa(nuovaSpesa)
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
