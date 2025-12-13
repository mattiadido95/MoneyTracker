# Export/Import System - Guida Completa

## 📋 Panoramica

Il sistema di export/import permette agli utenti di:
- **Esportare** i propri dati in un file JSON per backup o condivisione
- **Importare** dati da un file JSON che si integrano automaticamente con quelli esistenti

## 🏗️ Architettura

### 1. **ExportImportManager.swift** - Business Logic
Gestisce la logica di export/import e merge dei dati.

**Funzionalità:**
- `exportData(_:)` → Crea un file JSON temporaneo con timestamp
- `importData(from:)` → Legge e valida un file JSON
- `mergeExpenses(imported:existing:)` → Unisce i dati evitando duplicati

**Strategia di Merge:**
- Usa gli `ID` delle spese per identificare duplicati
- Le spese con ID già presenti vengono **ignorate**
- Solo le spese nuove vengono **aggiunte**
- Priorità ai dati locali in caso di conflitto

### 2. **DocumentPicker.swift** - UI per Import
Wrapper SwiftUI per `UIDocumentPickerViewController`.

**Cosa fa:**
- Mostra il file picker nativo di iOS
- Filtra solo file `.json`
- Restituisce l'URL del file selezionato via callback

### 3. **ActivityViewController.swift** - UI per Export
Wrapper SwiftUI per `UIActivityViewController`.

**Cosa fa:**
- Mostra lo share sheet nativo di iOS
- Permette di salvare su Files, inviare via AirDrop, Mail, etc.
- Notifica quando la condivisione è completata

### 4. **HomeView.swift** - Orchestrazione
Coordina l'intera esperienza utente.

**Componenti UI:**
- Menu toolbar con sezioni "Backup" e "Debug"
- Sheet per export (share sheet)
- Sheet per import (file picker)
- Alert per feedback (successo/errore)

**Metodi:**
- `handleExport()` → Chiama ExpenseManager.exportData()
- `handleImport(from:)` → Chiama ExpenseManager.importData(from:)

### 5. **ExpenseManager.swift** - Coordinamento Dati
Fornisce API semplici per export/import.

**Metodi pubblici:**
- `exportData() throws -> URL`
- `importData(from: URL) throws -> Int`

## 🔄 Flusso Completo

### Export Flow
```
User tap "Esporta Dati"
    ↓
HomeView.handleExport()
    ↓
ExpenseManager.exportData()
    ↓
ExportImportManager.exportData()
    ↓
Crea file JSON temporaneo con timestamp
    ↓
Restituisce URL
    ↓
HomeView mostra ActivityViewController (share sheet)
    ↓
User sceglie destinazione (Files, AirDrop, Mail, etc.)
    ↓
File salvato/inviato
    ↓
Alert di successo
```

### Import Flow
```
User tap "Importa Dati"
    ↓
HomeView mostra DocumentPicker
    ↓
User seleziona file .json
    ↓
HomeView.handleImport(from:)
    ↓
ExpenseManager.importData(from:)
    ↓
ExportImportManager.importData(from:)
    ↓
Legge e decodifica JSON
    ↓
ExportImportManager.mergeExpenses()
    ↓
Filtra duplicati (per ID)
    ↓
Aggiunge solo spese nuove
    ↓
ExpenseManager aggiorna categorieSpese
    ↓
didSet trigger → auto-save
    ↓
Alert con numero di spese aggiunte
```

## 📝 Formato File JSON

Il file esportato ha questo formato:

```json
[
  {
    "id": "A1B2C3D4-E5F6-7890-ABCD-EF1234567890",
    "nome": "Affitto",
    "importo": 800.0,
    "data": "2024-12-13T10:30:00Z",
    "coloreNome": "purple"
  },
  {
    "id": "B2C3D4E5-F6G7-8901-BCDE-F12345678901",
    "nome": "Luce",
    "importo": 89.5,
    "data": "2024-12-10T14:20:00Z",
    "coloreNome": "yellow"
  }
]
```

**Caratteristiche:**
- Pretty-printed (leggibile)
- Sorted keys (ordinato)
- Date in formato ISO8601
- Colori serializzati come stringhe

## 🎯 Gestione Errori

Tutti i possibili errori sono gestiti e mostrati all'utente:

| Scenario | Gestione |
|----------|----------|
| Export fallito | Alert: "Impossibile esportare i dati" + descrizione errore |
| File JSON non valido | Alert: "Impossibile importare i dati" + descrizione errore |
| File picker annullato | Nessun alert (comportamento normale) |
| Share sheet annullata | Nessun alert (comportamento normale) |
| Import senza nuove spese | Alert: "Import completato! Nessuna nuova spesa (tutte già presenti)" |
| Import con spese aggiunte | Alert: "Import completato! X spese aggiunte" |

## 🧪 Testing

### Come testare Export:
1. Aggiungi alcune spese nell'app
2. Tap menu (⋯) → "Esporta Dati"
3. Salva il file su Files o invialo via AirDrop
4. Verifica che il file esista e sia un JSON valido

### Come testare Import:
1. Esporta i dati (vedi sopra)
2. Elimina alcune spese dall'app (o usa Debug → Reset Dati)
3. Tap menu (⋯) → "Importa Dati"
4. Seleziona il file JSON precedentemente esportato
5. Verifica che le spese vengano ripristinate

### Come testare Merge (niente duplicati):
1. Esporta i dati
2. Importa lo stesso file
3. Verifica che non ci siano duplicati (alert: "0 spese aggiunte")

### Come testare Merge (con nuove spese):
1. Device A: Aggiungi spese e esporta
2. Device B: Aggiungi spese diverse e importa da Device A
3. Verifica che entrambi i set di spese siano presenti

## 🔐 Sicurezza e Privacy

- **File temporanei**: Creati nella directory temporanea di iOS, automaticamente eliminati dal sistema
- **Nessun upload cloud**: Tutti i dati rimangono sul dispositivo dell'utente
- **Controllo utente**: L'utente sceglie sempre dove salvare/da dove importare
- **Security-scoped resources**: Gestiti correttamente per l'accesso ai file picker

## 🚀 Possibili Miglioramenti Futuri

1. **iCloud Sync automatico**: Sincronizzazione tramite CloudKit
2. **Conflitto resolution UI**: Quando ci sono duplicati, chiedi all'utente quale mantenere
3. **Import parziale**: Checkbox per selezionare quali spese importare
4. **Export filtrato**: Esporta solo spese di un certo mese/anno
5. **Compressione**: File .zip per export grandi
6. **Cifratura**: Password-protect per dati sensibili
7. **Import da altri formati**: CSV, Excel, etc.

## 📱 UX Design Notes

**Placement:**
- Menu toolbar (non invasivo, ma facilmente accessibile)
- Icona ellipsis standard iOS (familiare agli utenti)

**Feedback:**
- Alert per successo/errore (chiaro e informativo)
- Console logs per debugging

**Discoverability:**
- Etichette chiare: "Esporta Dati" / "Importa Dati"
- Icone SF Symbols standard (square.and.arrow.up/down)
- Sezione dedicata nel menu ("Backup & Sincronizzazione")

## 🐛 Debug

Per vedere i log di export/import, cerca nella console:
- `📤 Export completato`
- `📥 Import completato`
- `🔀 Merge completato`
- `✅` per successi
- `❌` per errori

Per vedere le info del file di persistenza:
Menu → Debug → "Info File"
