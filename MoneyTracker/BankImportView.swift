//
//  BankImportView.swift
//  MoneyTracker
//
//  Created by Assistant on 14/12/25.
//

/*
 VIEW - Bank Import View (macOS)
 
 Schermata per importare estratti conto bancari da file XLSX.
 
 FEATURES:
 • File picker per XLSX
 • Progress indicator durante import
 • Preview transazioni importate
 • Statistiche import
 • Export JSON risultato
 • Error handling con alert
 
 ARCHITETTURA:
 • MVVM pattern con BankImportViewModel
 • Async/await per operazioni ETL
 • SwiftUI nativo per macOS
 
 UTILIZZO:
 BankImportView()
     .environmentObject(expenseManager)
*/

import SwiftUI
import UniformTypeIdentifiers
#if os(macOS)
import AppKit
#else
import UIKit
#endif

// MARK: - Colori cross-platform
private extension Color {
    static var platformWindowBackground: Color {
        #if os(macOS)
        Color(NSColor.windowBackgroundColor)
        #else
        Color(UIColor.systemBackground)
        #endif
    }
    static var platformControlBackground: Color {
        #if os(macOS)
        Color(NSColor.controlBackgroundColor)
        #else
        Color(UIColor.secondarySystemBackground)
        #endif
    }
}

struct BankImportView: View {
    
    // MARK: - Environment
    
    @EnvironmentObject var expenseManager: ExpenseManager
    @Environment(\.dismiss) var dismiss
    
    // MARK: - State
    
    @StateObject private var viewModel = BankImportViewModel()
    
    /// Mostra file importer
    @State private var showFileImporter = false
    
    /// Mostra sheet dettagli
    @State private var showDetailsSheet = false
    
    /// Mostra alert export success
    @State private var showExportAlert = false
    @State private var exportedFileURL: URL?

    /// Alert conferma import
    @State private var showConfirmAlert = false
    @State private var confirmAlertMessage = ""
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom Header con pulsante chiudi
            HStack {
                Text("Import Estratto Conto")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Chiudi") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
            }
            .padding()
            .background(Color.platformWindowBackground)
            
            Divider()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    headerSection
                    
                    Divider()
                    
                    // Content
                    contentSection
                    
                    // Bottom actions
                    if viewModel.importState.isSuccess {
                        actionsSection
                    }
                }
                .padding()
            }
        }
        .frame(minWidth: 700, minHeight: 600)
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [
                .init(filenameExtension: "xlsx")!,
                .init(filenameExtension: "xls")!
            ],
            allowsMultipleSelection: false
        ) { result in
            handleFileSelection(result)
        }
        .alert("Errore Import", isPresented: $viewModel.showErrorAlert) {
            Button("OK") {
                viewModel.showErrorAlert = false
            }
        } message: {
            Text(viewModel.errorMessage)
        }
        .alert("Export Completato", isPresented: $showExportAlert) {
            Button("OK") {}
            #if os(macOS)
            if let url = exportedFileURL {
                Button("Mostra nel Finder") {
                    NSWorkspace.shared.selectFile(
                        url.path,
                        inFileViewerRootedAtPath: url.deletingLastPathComponent().path
                    )
                }
            }
            #endif
        } message: {
            if let url = exportedFileURL {
                Text("File esportato in:\n\(url.path)")
            }
        }
        .alert("Import Confermato", isPresented: $showConfirmAlert) {
            Button("OK") { dismiss() }
        } message: {
            Text(confirmAlertMessage)
        }
        .sheet(isPresented: $showDetailsSheet) {
            if let report = viewModel.getReport() {
                ReportDetailView(report: report)
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text.fill")
                .font(.system(size: 48))
                .foregroundColor(.accentColor)
            
            Text("Importa Estratto Conto Bancario")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Seleziona un file XLS o XLSX per importare le transazioni")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Content Section
    
    @ViewBuilder
    private var contentSection: some View {
        switch viewModel.importState {
        case .idle:
            idleView
            
        case .processing:
            processingView
            
        case .success(let bankImport):
            successView(bankImport: bankImport)
            
        case .failure(let error):
            failureView(error: error)
        }
    }
    
    // MARK: - Idle View
    
    private var idleView: some View {
        VStack(spacing: 20) {
            Button(action: {
                showFileImporter = true
            }) {
                HStack {
                    Image(systemName: "square.and.arrow.down")
                    Text("Importa Estratto Conto")
                }
                .font(.headline)
                .frame(minWidth: 200)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            
            // Istruzioni
            GroupBox {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Formati supportati", systemImage: "doc.fill")
                        .font(.headline)
                    
                    Text("• File Excel (.xlsx / .xls)")
                    Text("• Prima riga come intestazione colonne")
                    Text("• Colonne richieste: Data, Descrizione, Importo")

                    Divider()
                        .padding(.vertical, 4)

                    Label("Banche supportate", systemImage: "building.columns.fill")
                        .font(.headline)

                    Text("• BPER Banca (XLS nativo)")
                    Text("• Intesa Sanpaolo")
                    Text("• Unicredit")
                    Text("• Altri formati generici")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }
            .frame(maxWidth: 500)
        }
    }
    
    // MARK: - Processing View
    
    private var processingView: some View {
        VStack(spacing: 20) {
            ProgressView(value: viewModel.importProgress) {
                Text("Importazione in corso...")
                    .font(.headline)
            } currentValueLabel: {
                Text(viewModel.progressMessage)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .progressViewStyle(.linear)
            .frame(width: 400)
            
            Text("Attendere prego...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Success View
    
    private func successView(bankImport: BankImport) -> some View {
        VStack(spacing: 16) {
            // Success indicator
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title)
                
                VStack(alignment: .leading) {
                    Text("Import completato con successo!")
                        .font(.headline)
                    
                    if let stats = viewModel.statistics {
                        Text("\(stats.validTransactions) transazioni importate (\(stats.formattedSuccessRate))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.green.opacity(0.1))
            .cornerRadius(8)
            
            // Statistics
            if let stats = viewModel.statistics {
                statisticsView(stats: stats)
            }
            
            // Preview transazioni
            if viewModel.hasTransactions {
                transactionPreviewSection
            }
        }
    }
    
    // MARK: - Failure View
    
    private func failureView(error: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.red)
            
            Text("Import fallito")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(error)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Riprova") {
                viewModel.reset()
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    // MARK: - Statistics View
    
    private func statisticsView(stats: ImportStatistics) -> some View {
        GroupBox {
            HStack(spacing: 30) {
                StatItem(
                    title: "Righe estratte",
                    value: "\(stats.extractedRows)",
                    icon: "doc.text"
                )
                
                Divider()
                
                StatItem(
                    title: "Trasformate",
                    value: "\(stats.transformedTransactions)",
                    icon: "arrow.triangle.2.circlepath"
                )
                
                Divider()
                
                StatItem(
                    title: "Valide",
                    value: "\(stats.validTransactions)",
                    icon: "checkmark.circle",
                    color: .green
                )
                
                Divider()
                
                StatItem(
                    title: "Scartate",
                    value: "\(stats.rejectedTransactions)",
                    icon: "xmark.circle",
                    color: .red
                )
            }
            .padding()
        } label: {
            Label("Statistiche Import", systemImage: "chart.bar.fill")
                .font(.headline)
        }
    }
    
    // MARK: - Transaction Preview Section
    
    private var transactionPreviewSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Preview Transazioni")
                        .font(.headline)
                    
                    Spacer()
                    
                    if let count = viewModel.bankImport?.transactionCount {
                        Text("Mostra \(min(count, 10)) di \(count)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Divider()
                
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(viewModel.previewTransactions) { transaction in
                            TransactionPreviewRow(transaction: transaction)
                        }
                    }
                }
                .frame(maxHeight: 300)
            }
            .padding()
        }
    }
    
    // MARK: - Actions Section
    
    private var actionsSection: some View {
        HStack(spacing: 12) {
            Button {
                showDetailsSheet = true
            } label: {
                Label("Mostra Report", systemImage: "doc.text")
            }
            .buttonStyle(.bordered)
            
            Button {
                exportJSON()
            } label: {
                Label("Esporta JSON", systemImage: "square.and.arrow.up")
            }
            .buttonStyle(.bordered)
            
            Spacer()
            
            Button {
                confirmImport()
            } label: {
                Label("Conferma Import", systemImage: "checkmark")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.horizontal)
    }
    
    // MARK: - Private Methods
    
    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let fileURL = urls.first else { return }
            
            // Start import
            Task {
                await viewModel.importFile(from: fileURL)
            }
            
        case .failure(let error):
            viewModel.errorMessage = error.localizedDescription
            viewModel.showErrorAlert = true
        }
    }
    
    private func exportJSON() {
        do {
            if let result = try viewModel.exportToJSON() {
                exportedFileURL = result.fileURL
                showExportAlert = true
                print("✅ Export JSON completato: \(result.fileURL.path)")
            }
        } catch {
            viewModel.errorMessage = "Export fallito: \(error.localizedDescription)"
            viewModel.showErrorAlert = true
        }
    }
    
    private func confirmImport() {
        guard let bankImport = viewModel.bankImport else { return }

        Task {
            let resolver = MockCategoryResolver()
            let expenses = bankImport.transactions.filter { $0.type == .expense }

            // Categorizza ogni transazione con MockCategoryResolver
            var nuoveSpese: [CategoriaSpesa] = []
            for tx in expenses {
                let result = await resolver.resolveCategory(for: tx)
                let spesa = CategoriaSpesa(
                    nome: tx.description,
                    importo: tx.amount,
                    colore: CategoriaSpesa.colorForCategoria(result.category),
                    data: tx.date,
                    categoria: result.category
                )
                nuoveSpese.append(spesa)
            }

            // Batch insert — didSet si attiva una volta sola → un solo salvataggio
            expenseManager.categorieSpese.append(contentsOf: nuoveSpese)

            let skipped = bankImport.transactions.count - expenses.count
            var msg = "Aggiunte \(nuoveSpese.count) spese da \(bankImport.bankName)."
            if skipped > 0 {
                msg += "\n(\(skipped) entrate escluse)"
            }
            confirmAlertMessage = msg
            showConfirmAlert = true

            print("✅ Import confermato: \(nuoveSpese.count) spese aggiunte, \(skipped) entrate saltate")
        }
    }
}

// MARK: - Stat Item

struct StatItem: View {
    let title: String
    let value: String
    let icon: String
    var color: Color = .primary
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(minWidth: 100)
    }
}

// MARK: - Transaction Preview Row

struct TransactionPreviewRow: View {
    let transaction: BankTransaction
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon tipo transazione
            transactionTypeIcon
            
            // Content principale
            VStack(alignment: .leading, spacing: 8) {
                // Prima riga: Descrizione e Importo
                HStack(alignment: .top) {
                    Text(transaction.description)
                        .font(.body)
                        .fontWeight(.medium)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Spacer()
                    
                    Text(transaction.formattedAmount)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(transaction.type == .income ? .green : .red)
                }
                
                // Seconda riga: Data e Categoria
                HStack(spacing: 12) {
                    // Data
                    Label {
                        Text(formatDate(transaction.date))
                            .font(.caption)
                    } icon: {
                        Image(systemName: "calendar")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                    
                    Divider()
                        .frame(height: 12)
                    
                    // Categoria (placeholder per AI futura)
                    categoryView
                }
            }
        }
        .padding(12)
        .background(Color.platformControlBackground)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
    
    // MARK: - Subviews
    
    private var transactionTypeIcon: some View {
        ZStack {
            Circle()
                .fill(transaction.type == .income ? Color.green.opacity(0.15) : Color.red.opacity(0.15))
                .frame(width: 40, height: 40)
            
            Image(systemName: transaction.type == .income ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                .foregroundColor(transaction.type == .income ? .green : .red)
                .font(.title3)
        }
    }
    
    private var categoryView: some View {
        HStack(spacing: 6) {
            Image(systemName: "tag")
                .font(.caption)
            
            if let category = transaction.category {
                // Categoria esistente (dal file)
                Text(category)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.accentColor.opacity(0.15))
                    .foregroundColor(.accentColor)
                    .cornerRadius(4)
            } else {
                // Placeholder per categorizzazione futura AI
                Text("Non categorizzato")
                    .font(.caption)
                    .italic()
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.gray.opacity(0.1))
                    .foregroundColor(.secondary)
                    .cornerRadius(4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.gray.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [3, 2]))
                    )
            }
        }
        .foregroundColor(.secondary)
    }
    
    // MARK: - Helpers
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy"
        formatter.locale = Locale(identifier: "it_IT")
        return formatter.string(from: date)
    }
}

// MARK: - Report Detail View

struct ReportDetailView: View {
    let report: String
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Report Dettagliato")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Chiudi") {
                    dismiss()
                }
            }
            .padding()
            
            Divider()
            
            // Content
            ScrollView {
                Text(report)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
        }
        .frame(width: 700, height: 500)
    }
}

// MARK: - Preview

struct BankImportView_Previews: PreviewProvider {
    static var previews: some View {
        BankImportView()
            .environmentObject(ExpenseManager(mockData: true))
    }
}
