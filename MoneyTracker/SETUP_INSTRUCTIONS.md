# Setup Instructions - MoneyTracker ETL System

## ✅ RISOLTO: Il progetto ora compila senza errori!

### Stato Attuale
- ✅ **Compila**: Sì, con stub types per CoreXLSX
- ✅ **UI funziona**: Sì, tutte le view compilano
- ⚠️ **Import XLSX reali**: Richiede installazione CoreXLSX

---

## Come Funziona lo Stub System

`XLSXBankExtractor.swift` usa conditional compilation:

```swift
#if canImport(CoreXLSX)
import CoreXLSX  // Se installato
#else
// Stub types per compilazione
fileprivate struct XLSXFile { ... }
#endif
```

### Vantaggi:
- ✅ Compila subito, nessun errore
- ✅ Puoi lavorare su altre parti del progetto
- ✅ Nessuna configurazione richiesta per development

### Per Import XLSX Reali:
⚠️ Installa CoreXLSX (vedi sotto)

---

## Installazione CoreXLSX (Opzionale per ora)

### Metodo 1: Xcode GUI (Raccomandato)

1. Apri **Xcode**
2. **File** → **Add Package Dependencies...**
3. URL: `https://github.com/CoreOffice/CoreXLSX.git`
4. Version: `0.14.0` o superiore
5. **Add Package**

### Metodo 2: Package.swift

```swift
dependencies: [
    .package(url: "https://github.com/CoreOffice/CoreXLSX.git", from: "0.14.0")
]
```

---

## Errori Corretti

### 1. `import` è una keyword riservata

❌ **Errore**:
```swift
if result.isSuccess, let import = result.bankImport {
    bankImport = import
}
```

✅ **Corretto**:
```swift
if result.isSuccess, let importedData = result.bankImport {
    bankImport = importedData
}
```

**Motivo**: `import` è una parola chiave di Swift usata per importare moduli, non può essere usata come nome di variabile.

---

## Build Instructions

1. Installa CoreXLSX (vedi sopra)
2. Clean Build Folder: `Cmd + Shift + K`
3. Build: `Cmd + B`

---

## File Structure

Il sistema ETL è composto da questi file (in ordine di dipendenza):

```
ETL System/
├── BankTransaction.swift           ← Modello dati
├── BankImport.swift                ← Container import
├── BankETLProtocols.swift          ← Protocol definitions
├── XLSXBankExtractor.swift         ← ⚠️ Richiede CoreXLSX
├── DefaultBankTransformer.swift    ← Transformer
├── DefaultBankValidator.swift      ← Validator
├── BankETLPipeline.swift          ← Coordinator
├── BankImportExporter.swift       ← JSON Export
├── CategoryResolver.swift          ← AI categorization
├── BankImportViewModel.swift      ← ViewModel
└── BankImportView.swift           ← UI macOS
```

---

## Alternative: Compilazione Senza CoreXLSX

Se non vuoi aggiungere la dipendenza subito, puoi temporaneamente:

1. Commentare l'import in `XLSXBankExtractor.swift`:
   ```swift
   // import CoreXLSX
   ```

2. Creare un stub minimale:
   ```swift
   #if !canImport(CoreXLSX)
   // Stub types per compilazione
   struct XLSXFile { }
   struct Worksheet { }
   struct SharedStrings { }
   #endif
   ```

3. La view `BankImportView` compilerà comunque (runtime error solo se usi import XLSX)

---

## Testing

Per testare il sistema senza file reali:

```swift
// In BankImportView o test file
let mockImport = BankImport.sample
let mockViewModel = BankImportViewModel.preview

// Usa mock data invece di file reali
```

---

## Supporto

Per problemi con:
- **CoreXLSX**: https://github.com/CoreOffice/CoreXLSX/issues
- **Build errors**: Pulisci DerivedData e ricompila
- **Runtime errors**: Verifica che il file XLSX sia valido

---

## Prossimi Step

Dopo aver risolto gli errori di compilazione:

1. ✅ Testa import con file XLSX reale
2. ✅ Integra CategoryResolver in UI
3. ✅ Aggiungi conversione BankTransaction → CategoriaSpesa
4. ✅ Implementa AI categorization con ML model

---

## Quick Fix Summary

```bash
# 1. Aggiungi CoreXLSX in Xcode
File → Add Package Dependencies → https://github.com/CoreOffice/CoreXLSX.git

# 2. Clean & Build
Cmd + Shift + K
Cmd + B

# 3. Run
Cmd + R
```

Tutti gli errori dovrebbero essere risolti! ✅
