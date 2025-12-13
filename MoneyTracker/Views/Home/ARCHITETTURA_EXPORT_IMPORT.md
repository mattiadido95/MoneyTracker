# 📐 Architettura Export/Import - Diagramma

## 🏗️ Struttura dei File

```
MoneyTracker/
│
├── Models/
│   └── CategoriaSpesa.swift          // Modello dati (Codable)
│
├── Services/
│   ├── PersistenceManager.swift      // Salva/Carica da Application Support
│   └── ExportImportManager.swift     // Export/Import/Merge logic
│
├── ViewModels/
│   └── ExpenseManager.swift          // ViewModel principale (ObservableObject)
│
├── Views/
│   └── HomeView.swift                // UI + Orchestrazione Export/Import
│
└── Helpers/
    ├── DocumentPicker.swift          // UIKit → SwiftUI bridge (file picker)
    └── ActivityViewController.swift  // UIKit → SwiftUI bridge (share sheet)
```

## 🔄 Flusso Dati - Export

```
┌─────────────────────────────────────────────────────────────────┐
│                           USER ACTION                            │
│                    Tap "Esporta Dati" button                     │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                          HomeView.swift                          │
│                     handleExport() method                        │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                      ExpenseManager.swift                        │
│        exportData() → passa categorieSpese[] al service          │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                   ExportImportManager.swift                      │
│  exportData(categorieSpese[]) → crea JSON temporaneo + timestamp │
│                                                                   │
│  1. JSONEncoder.encode(categorieSpese)                           │
│  2. Write to temp directory                                      │
│  3. Return file URL                                              │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                          HomeView.swift                          │
│       Store fileURL → Show ActivityViewController (share)        │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                  ActivityViewController.swift                    │
│           UIActivityViewController → Share Sheet UI              │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                           USER CHOICE                            │
│       Save to Files / AirDrop / Mail / Messages / etc.           │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                          HomeView.swift                          │
│         Show alert: "File esportato con successo!"               │
└─────────────────────────────────────────────────────────────────┘
```

## 🔄 Flusso Dati - Import

```
┌─────────────────────────────────────────────────────────────────┐
│                           USER ACTION                            │
│                    Tap "Importa Dati" button                     │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                          HomeView.swift                          │
│               Show DocumentPicker (file picker UI)               │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                      DocumentPicker.swift                        │
│        UIDocumentPickerViewController → File Picker UI           │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                           USER CHOICE                            │
│                   Select JSON file to import                     │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                          HomeView.swift                          │
│          handleImport(from: fileURL) → pass to manager           │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                      ExpenseManager.swift                        │
│     importData(from: fileURL) → coordina import + merge          │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                   ExportImportManager.swift                      │
│              importData(from: fileURL) → decode JSON             │
│                                                                   │
│  1. Read file with security scoped resources                     │
│  2. JSONDecoder.decode([CategoriaSpesa].self)                    │
│  3. Return imported expenses array                               │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                   ExportImportManager.swift                      │
│    mergeExpenses(imported:, existing:) → smart merge logic       │
│                                                                   │
│  1. Create Set of existing IDs                                   │
│  2. Filter imported: keep only new IDs                           │
│  3. Return existing + new (no duplicates)                        │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                      ExpenseManager.swift                        │
│    categorieSpese = merged array → didSet triggers auto-save     │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                    PersistenceManager.swift                      │
│         save(categorieSpese) → persist to Application Support    │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                          HomeView.swift                          │
│         Show alert: "Import completato! X spese aggiunte"        │
└─────────────────────────────────────────────────────────────────┘
```

## 🎯 Responsabilità dei Componenti

### 📱 HomeView.swift
**Responsabilità:** UI + Orchestrazione
- Mostra i bottoni Export/Import nel menu
- Gestisce gli state per sheet/picker/alert
- Coordina le azioni utente
- Mostra feedback (alert)

**Non fa:**
- ❌ Logica di export/import
- ❌ Gestione file system
- ❌ Merge dei dati

---

### 🧠 ExpenseManager.swift
**Responsabilità:** ViewModel + Coordinamento
- Espone API semplici: `exportData()`, `importData(from:)`
- Coordina tra UI e Service layer
- Gestisce `categorieSpese` array
- Trigger auto-save via `didSet`

**Non fa:**
- ❌ Creazione diretta dei file
- ❌ Merge logic
- ❌ UI management

---

### 🛠️ ExportImportManager.swift
**Responsabilità:** Business Logic Export/Import
- Crea file JSON temporaneo con timestamp
- Legge e valida file JSON
- **Smart merge:** evita duplicati per ID
- Logging dettagliato

**Non fa:**
- ❌ UI (non sa dell'esistenza di SwiftUI)
- ❌ Auto-save (non modifica ExpenseManager)
- ❌ Persistenza permanente (solo temp files)

---

### 💾 PersistenceManager.swift
**Responsabilità:** Persistenza Locale
- Salva su Application Support directory
- Carica da Application Support directory
- File permanente: `spese.json`

**Non fa:**
- ❌ Export (non crea file temporanei)
- ❌ Merge (non sa della logica di duplicati)
- ❌ UI

---

### 🖼️ DocumentPicker.swift
**Responsabilità:** UIKit → SwiftUI Bridge
- Mostra UIDocumentPickerViewController
- Filtra solo `.json` files
- Callback con file URL selezionato

**Non fa:**
- ❌ Lettura del file
- ❌ Validazione JSON
- ❌ Qualsiasi business logic

---

### 📤 ActivityViewController.swift
**Responsabilità:** UIKit → SwiftUI Bridge
- Mostra UIActivityViewController (share sheet)
- Gestisce completion handler
- Notifica quando completato

**Non fa:**
- ❌ Creazione del file
- ❌ Validazione
- ❌ Qualsiasi business logic

---

## 🔐 Sicurezza e Accesso File

### Application Support Directory (Persistenza)
```
/var/mobile/Containers/Data/Application/[APP_ID]/
    Library/
        Application Support/
            spese.json  ← File permanente, auto-save
```
- ✅ Privato all'app
- ✅ Backed up su iCloud (se abilitato)
- ✅ Sopravvive agli update dell'app
- ✅ Non accessibile direttamente dall'utente

### Temporary Directory (Export)
```
/var/mobile/Containers/Data/Application/[APP_ID]/
    tmp/
        MoneyTracker_Export_2024-12-13_143025.json  ← File temporaneo
```
- ✅ Automaticamente eliminato da iOS
- ✅ Usato solo per condivisione
- ⚠️ Non persistente (può essere cancellato in qualsiasi momento)

### User Documents (Import)
```
File selezionato dall'utente tramite file picker
Può essere ovunque: iCloud Drive, Files app, etc.
```
- ✅ Accesso tramite security-scoped resources
- ✅ `startAccessingSecurityScopedResource()` / `stopAccessingSecurityScopedResource()`
- ⚠️ Permessi limitati: solo lettura, solo per la durata dell'import

---

## 🎨 Design Patterns Utilizzati

### 1. **Service Layer Pattern**
`ExportImportManager` è un service che incapsula la logica di business.

### 2. **Repository Pattern**
`PersistenceManager` è un repository per l'accesso ai dati.

### 3. **MVVM (Model-View-ViewModel)**
- **Model:** `CategoriaSpesa`
- **View:** `HomeView`
- **ViewModel:** `ExpenseManager`

### 4. **Coordinator Pattern**
I `UIViewControllerRepresentable` usano Coordinator per gestire delegate.

### 5. **Single Responsibility Principle**
Ogni componente ha una singola responsabilità ben definata.

### 6. **Dependency Injection**
`ExpenseManager` riceve `PersistenceManager` e `ExportImportManager` come dipendenze (implicito via static methods).

---

## 📊 Data Flow Summary

```
       ┌─────────────────────────┐
       │   CategoriaSpesa[]      │  ← Model
       │  (Source of Truth)      │
       └────────────┬────────────┘
                    │
         ┌──────────▼──────────┐
         │  ExpenseManager     │  ← ViewModel (@Published)
         │  (ObservableObject) │
         └──────────┬──────────┘
                    │
         ┌──────────▼──────────┐
         │     HomeView        │  ← View (@EnvironmentObject)
         └─────────────────────┘
                    │
       ┌────────────┴────────────┐
       │                         │
┌──────▼──────┐         ┌───────▼─────┐
│   Export    │         │   Import    │
└──────┬──────┘         └───────┬─────┘
       │                        │
┌──────▼──────────────┐  ┌──────▼──────────────┐
│ ExportImportManager │  │ ExportImportManager │
│   .exportData()     │  │   .importData()     │
└──────┬──────────────┘  └──────┬──────────────┘
       │                        │
┌──────▼──────────┐      ┌──────▼──────────┐
│ Temporary File  │      │ User File       │
│ (Share)         │      │ (Merge → Save)  │
└─────────────────┘      └─────────────────┘
```

---

## ✅ Conclusione

Questa architettura garantisce:
- ✅ **Separazione delle responsabilità**
- ✅ **Testabilità** (ogni componente è testabile singolarmente)
- ✅ **Manutenibilità** (modifiche isolate)
- ✅ **Riusabilità** (i service possono essere usati altrove)
- ✅ **Type Safety** (Swift type system)
- ✅ **Error Handling** (try/catch everywhere)
- ✅ **User Feedback** (alert per ogni azione)
- ✅ **Logging** (console output per debug)

🎉 Sistema completo e production-ready!
