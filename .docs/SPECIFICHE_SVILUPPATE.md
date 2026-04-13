# MoneyTracker - Specifiche Sviluppate

Documentazione completa di tutte le funzionalita implementate nel progetto.

---

## 1. Architettura Generale

- **Pattern:** MVVM (Model-View-ViewModel) con SwiftUI
- **Design:** Protocol-Oriented, Dependency Inversion, Single Responsibility
- **Piattaforme:** iOS (iPhone/iPad) + macOS
- **Minimo:** iOS 16.0+ (per Swift Charts)
- **Struttura progetto:**
  - `Models/` — CategoriaSpesa
  - `ViewModels/` — ExpenseManager, BankImportViewModel
  - `Views/Home/` — HomeView, HeaderCard, AddExpenseButton, ImportExportAlert, DocumentPicker, ActivityViewController
  - `Views/Components/` — CategoriesSection, CategoryRow, SummaryCard, SummaryCardsGrid
  - `Services/` — PersistenceManager, ExportImportManager, BankImportExporter
  - `Bank Import System/` — BankTransaction, BankImport, BankETLProtocols, BankETLPipeline, XLSXBankExtractor, DefaultBankTransformer, DefaultBankValidator, BankImportView, BankImportViewModel, CategoryResolver

---

## 2. Gestione Spese (Core)

### Modello Dati — CategoriaSpesa
- Proprietà: `id: UUID`, `nome: String`, `importo: Double`, `colore: String`, `data: Date`
- Conforme a `Codable`, `Identifiable`
- Formato JSON: date ISO8601, colori come stringhe, pretty-printed

### ExpenseManager (ViewModel principale)
- `ObservableObject` con proprietà `@Published`
- Auto-save tramite `didSet` su `categorieSpese`
- Auto-load in `init()` (con `autoSaveEnabled = false` durante init per evitare crash da `didSet` ricorsivo)
- Modalità preview: `init(mockData: true)` per SwiftUI Previews (auto-save disabilitato, dati in memoria)
- Calcolo automatico totali mensili, annuali, medie

### AddExpenseView
- Form per aggiungere nuove spese
- Campi: nome, importo, colore, data
- Presentata come sheet dalla HomeView

### Eliminazione
- Swipe-to-delete nella lista spese (CategoriesSection)
- Eliminazione context-aware con filtri e ordinamento attivi

---

## 3. Persistenza Dati

### PersistenceManager
- Singleton statico per I/O su file JSON
- Directory: `Application Support` (privata, persistente, backup iCloud)
- File: `Library/Application Support/spese.json`
- Scrittura atomica per integrità dati
- Encoder/Decoder con date ISO8601
- Migrato da `Documents` a `Application Support` per best practice iOS
- Debug: `expenseManager.mostraInfoFile()` per stampare il path

---

## 4. Lista Spese Completa (ExpenseListView)

- ~330 righe di codice
- Accesso tramite "Vedi Tutto" (visibile solo con spese presenti)
- **Filtri:** Tutte, Mese Corrente, Anno Corrente
- **Ordinamento:** Più recenti, Più vecchie, Importo decrescente, Importo crescente
- **Riga:** nome, data formattata, data relativa, importo, indicatore colore, prefisso UUID
- Empty state dedicato
- Eliminazione contestuale (funziona con filtri/ordinamento attivi)

---

## 5. Statistiche e Grafici (StatisticsView)

- Accesso: pulsante verde "Vedi Statistiche e Grafici" nella HomeView
- Richiede iOS 16.0+ per Swift Charts
- **Filtri temporali:** 1 mese, 3 mesi (default), 6 mesi, 1 anno, tutti
- **Header stats:** totale periodo, media mensile, conteggio spese, periodo selezionato
- **Grafici:**
  - Barre orizzontali — spese per categoria
  - Linea + area — trend mensile (interpolazione catmullRom)
  - Donut — distribuzione top 5 categorie

---

## 6. Export/Import

### ExportImportManager
- ~208 righe
- Esportazione: crea file JSON temporaneo condivisibile
- Importazione: legge file JSON, merge con deduplicazione per UUID
- Strategia merge: priorità dati locali, aggiunge solo UUID nuovi

### DocumentPicker (~80 righe)
- Bridge UIKit per `UIDocumentPickerViewController`
- Selezione file `.json` per importazione
- Gestione security-scoped resources

### ActivityViewController (~70 righe)
- Bridge UIKit per condivisione (AirDrop, Mail, iCloud, Files)

### ImportExportAlert
- File separato con factory methods: `.success()` e `.error()`
- Parametro `isError: Bool` per styling

### Sicurezza
- File temporanei per export (auto-eliminati)
- Nessun upload cloud automatico
- Risorse security-scoped per import

---

## 7. Pipeline ETL — Import Estratti Conto Bancari

### Modelli Dati

**BankTransaction (transazione normalizzata):**
- Proprietà: `id`, `date`, `amount`, `type` (expense/income), `currency`, `description`, `category`, `notes`, `counterparty`, `originalID`, `bankSource`
- Amount sempre positivo; `signedAmount` determina il segno in base al type
- Valute supportate: EUR, USD, GBP, CHF

**BankImport (contenitore import):**
- Array di `BankTransaction`
- Metadata: `bankName`, `accountType`, `periodStart`, `periodEnd`, `importedAt`, `sourceFileName`, `sourceFormat`
- Statistiche calcolate: `totalExpenses`, `totalIncome`, `netBalance`, `transactionCount`

### Fasi del Pipeline

**Extract — XLSXBankExtractor:**
- Legge file XLSX tramite CoreXLSX (con stub condizionale `#if canImport(CoreXLSX)`)
- Restituisce `RawBankRow` (solo stringhe)
- Configurabile: gestione header, skip righe vuote, validazione colonne
- Zero logica business

**Transform — DefaultBankTransformer:**
- Converte `RawBankRow` -> `BankTransaction`
- `parseDate()`: supporta 10+ formati (italiano, ISO8601, inglese)
- `parseAmount()`: gestisce formati numerici vari (virgola/punto, simboli valuta)
- `normalizeDescription()`: pulizia whitespace e formattazione
- Inferenza tipo: rileva income/expense da keyword
- Configurabile tramite `BankColumnMapping`
- `transactionDescription` (rinominato da `description` per evitare conflitto con `CustomStringConvertible`)

**Validate — DefaultBankValidator:**
- Regole componibili:
  - `DateValidationRule`: range date (10 anni indietro — domani)
  - `AmountValidationRule`: amount > 0, min/max, warning importi insoliti
  - `DescriptionValidationRule`: non vuota, lunghezza minima
  - `OptionalFieldsRule`: warning campi opzionali mancanti
- `BankValidationResult`: transazioni valide/invalide, errori dettagliati, warning, percentuale successo

**Orchestrazione — BankETLPipeline:**
- Coordina Extract -> Transform -> Validate -> Load
- Soglie qualità configurabili:
  - Default: 80% transform, 70% validation
  - Strict: 95% entrambe
  - Lenient: 50% entrambe
- `ETLPipelineResult`: statistiche per fase, success rate, report testuale, tempo di elaborazione

### BankImportExporter
- Export `BankImport` in JSON
- Directory output configurabile
- Strategie naming: `bankAndDate`, `uuid`, `timestamp`, `custom`
- JSON pretty-printed con chiavi ordinate
- Utility: lista, eliminazione file esportati

### BankImportViewModel
- `ObservableObject` con macchina a stati: `idle`, `processing`, `success(BankImport)`, `failure(String)`
- Tracking progresso (0.0-1.0) con messaggi
- Preview prime 10 transazioni
- Export JSON

### BankImportView (macOS)
- File picker per XLSX
- Indicatore progresso real-time
- Preview transazioni con indicatori tipo
- Statistiche (estratte, trasformate, valide, rifiutate)
- Viewer report dettagliato
- Export JSON

---

## 8. CategoryResolver (Rule-Based)

### Protocollo
- `resolveCategory(for:)` — classifica singola transazione
- `resolveCategories(for:)` — classifica batch
- `supportsLearning` — indica se supporta apprendimento
- `provideFeedback(transaction:correctCategory:)` — feedback utente

### MockCategoryResolver (implementazione attuale)
- Matching keyword-based su 13+ categorie italiane:
  - Utenze (luce, gas, acqua), Telecomunicazioni, Trasporti, Alimentari, Ristorazione, Salute, Affitto, Intrattenimento, Abbigliamento, Casa, Stipendio, Bonifico, Prelievo
- **Sistema di confidence (0.0-1.0):**
  - 3+ keyword match: 95%
  - 2 keyword match: 85%
  - 1 keyword, nessuna alternativa: 75%
  - 1 keyword con alternative: 55%
  - Nessun match: 20% (categoria generica)
- Livelli: Low (0-0.3), Medium (0.3-0.7), High (0.7-1.0)
- `isReliable` >= 0.7, `needsHumanReview` < 0.5
- Alternative: restituisce le 2 migliori categorie alternative con confidence
- Reasoning: spiega quali keyword hanno matchato
- `ResolutionMethod`: ruleBased, machineLearning, userHistory, hybrid, manual
- Feedback: salva cronologia per matching futuro

---

## 9. UI / Empty States

- Empty state in CategoriesSection: icona tray + "Nessuna spesa registrata"
- "Vedi Tutto" visibile solo quando ci sono spese
- Rimozione completa dati mock/esempio dal codice produzione
- `resetDati()` non ricarica più mock

---

## 10. Fix e Problemi Risolti

- **Duplicate type definitions:** ImportExportAlert, ActivityViewController, DocumentPicker — risolto con file separati e factory methods
- **Preview crash:** `autoSaveEnabled` flag + `init(mockData:)` per preview
- **EnvironmentObject mancante nei preview:** tutti i preview aggiornati con `ExpenseManager(mockData: true)`
- **didSet ricorsivo durante init:** `autoSaveEnabled = false` durante init
- **File duplicato CategoriesSection_NEW.swift:** eliminato
- **Import Combine mancante:** aggiunto a BankImportViewModel
- **Equatable per BankImportState:** implementato operatore `==`
- **Ordine argomenti BankETLPipeline.generic():** corretto `columnMapping` prima di `configuration`
- **Conflitto `description`:** rinominato in `transactionDescription` in RawBankRow
- **CoreXLSX condizionale:** stub types come fallback
- **`transactionIndex` let -> var**
- **Estensione duplicata DefaultBankValidator:** rimossa
- **Compiler type inference HomeView:** estratto `@ViewBuilder dashboardContent`

---

## 11. Configurazione e Setup

- **CoreXLSX:** versione 0.14.0+, installabile via Xcode GUI o Package.swift
- Compilazione condizionale con `#if canImport(CoreXLSX)` e stub types come fallback
- 14/14 file Swift compilano correttamente
- Debug: console log con emoji-tag per tracciamento
