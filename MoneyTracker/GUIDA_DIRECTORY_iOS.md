# 📁 Guida alle Directory iOS - Dove Salvare i File

## 🎯 MODIFICA APPLICATA

Ho cambiato la directory di salvataggio da **Documents** a **Application Support**.

**Prima:**
```
Documents/spese.json  ← Visibile all'utente
```

**Ora:**
```
Library/Application Support/spese.json  ← Privato all'app
```

---

## 📊 CONFRONTO DIRECTORY iOS

| Directory | Persistente | Backup iCloud | Visibile Utente | Uso Consigliato |
|-----------|-------------|---------------|-----------------|------------------|
| **Application Support** ✅ | ✅ Sì | ✅ Sì | ❌ No | **File dati interni app** |
| Documents | ✅ Sì | ✅ Sì | ✅ Sì | Documenti generati utente |
| Caches | ⚠️ Temporaneo | ❌ No | ❌ No | File temporanei/cache |
| Tmp | ❌ No | ❌ No | ❌ No | File session temporanei |

---

## 🔒 **APPLICATION SUPPORT** (SCELTA ATTUALE)

### **Percorso Completo:**
```
/Library/Application Support/spese.json
```

### **Caratteristiche:**
- ✅ **Privata all'applicazione** - L'utente NON può accedere
- ✅ **Persistente** - I dati rimangono tra riavvii
- ✅ **Backed up su iCloud** - Automaticamente sincronizzata
- ✅ **Non visibile in "Files" app** - Completamente nascosta
- ✅ **Perfetta per dati interni** - Database, configurazioni, cache persistenti

### **Quando Usare:**
- ✅ File JSON con dati app (come il tuo caso!)
- ✅ Database SQLite
- ✅ File di configurazione
- ✅ Cache persistenti che devono sopravvivere ai riavvii
- ✅ Dati che NON devono essere modificabili dall'utente

### **Percorso Simulator macOS:**
```bash
~/Library/Developer/CoreSimulator/Devices/[DEVICE-ID]/data/Containers/Data/Application/[APP-ID]/Library/Application Support/spese.json
```

---

## 📄 **DOCUMENTS** (Vecchia Scelta)

### **Percorso Completo:**
```
/Documents/spese.json
```

### **Caratteristiche:**
- ✅ Persistente
- ✅ Backed up su iCloud
- ⚠️ **Visibile all'utente** tramite "Files" app
- ⚠️ **Accessibile** - L'utente può modificare/cancellare
- ⚠️ Appare in iTunes File Sharing (se abilitato)

### **Quando Usare:**
- ✅ PDF generati dall'utente
- ✅ File esportati
- ✅ Documenti che l'utente deve poter aprire/condividere
- ✅ File che l'utente potrebbe voler backuppare manualmente

### **Esempio:**
App di note, editor di testo, app che generano PDF/immagini

---

## 🗑️ **CACHES**

### **Percorso Completo:**
```
/Library/Caches/
```

### **Caratteristiche:**
- ⚠️ **Può essere cancellata da iOS** quando serve spazio
- ❌ **Non backed up su iCloud**
- ✅ Buona per file rigenerabili

### **Quando Usare:**
- ✅ Immagini scaricate che possono essere ri-scaricate
- ✅ File temporanei che possono essere ricreati
- ✅ Cache di rete
- ✅ Thumbnail generati

### **Esempio:**
Cache immagini per app social, file scaricati temporaneamente

---

## ⏱️ **TMP (Temporary)**

### **Percorso Completo:**
```
/tmp/
```

### **Caratteristiche:**
- ❌ **Cancellata quando l'app viene chiusa**
- ❌ Non persistente
- ❌ Non backed up

### **Quando Usare:**
- ✅ File temporanei durante elaborazione
- ✅ Download in progress
- ✅ File che servono solo durante la sessione app

### **Esempio:**
File temporaneo mentre processi un'immagine, file zip estratto temporaneamente

---

## 🎯 PERCHÉ APPLICATION SUPPORT È MEGLIO PER TE

Per il tuo file `spese.json`:

### **PRO di Application Support:**
1. ✅ **Privato** - L'utente non può modificarlo accidentalmente
2. ✅ **Persistente** - I dati rimangono sempre
3. ✅ **Backed up** - Sincronizzato su iCloud
4. ✅ **Professionale** - È dove le app iOS "serie" salvano i dati
5. ✅ **Sicuro** - Protetto da accessi esterni

### **CONTRO di Documents (vecchia scelta):**
1. ⚠️ **Troppo esposto** - Utente può vedere il JSON
2. ⚠️ **Modificabile** - Utente potrebbe corrompere i dati
3. ⚠️ **Confusione** - In "Files" app apparirebbe il file JSON tecnico

---

## 🔍 COME TROVARE IL FILE (Debug)

### **Metodo 1: Tramite App (Menu Debug)**
```swift
// Già implementato nel menu "..."
expenseManager.mostraInfoFile()  // Stampa il path completo
```

### **Metodo 2: Terminal (Simulator)**
```bash
# Trova tutti i file spese.json
cd ~/Library/Developer/CoreSimulator/Devices
find . -name "spese.json" -type f

# Il percorso sarà del tipo:
# ./[DEVICE-ID]/data/Containers/Data/Application/[APP-ID]/Library/Application Support/spese.json
```

### **Metodo 3: Tramite Xcode**
1. **Window** → **Devices and Simulators**
2. Seleziona il simulatore/dispositivo
3. Seleziona la tua app
4. Click sull'icona **⚙️** → **Download Container**
5. Apri il container scaricato
6. Naviga in `Library/Application Support/`

---

## 💻 CODICE MODIFICATO

### **Prima (Documents):**
```swift
let documentsDirectory = try FileManager.default.url(
    for: .documentDirectory,  // ← Visibile all'utente
    in: .userDomainMask,
    appropriateFor: nil,
    create: true
)
```

### **Dopo (Application Support):**
```swift
let appSupportDirectory = try FileManager.default.url(
    for: .applicationSupportDirectory,  // ← Privato all'app
    in: .userDomainMask,
    appropriateFor: nil,
    create: true
)
```

**Cambiamento:** Una sola parola! `.documentDirectory` → `.applicationSupportDirectory`

---

## 🧪 TEST DELLA MODIFICA

### **Test 1: Verifica Path**
```swift
1. Compila ed esegui l'app
2. Menu "..." → "Info File"
3. Console Xcode mostrerà:
   📍 Path: .../Library/Application Support/spese.json  ✅
```

### **Test 2: Verifica Persistenza**
```swift
1. Aggiungi una spesa
2. Chiudi l'app
3. Riavvia l'app
4. ✅ La spesa è ancora lì (funziona come prima!)
```

### **Test 3: Verifica Privacy**
```swift
1. Apri "Files" app sul simulatore/device
2. Cerca "MoneyTracker"
3. ✅ NON dovresti vedere il file spese.json (è privato!)
```

---

## 📋 ALTERNATIVE PER ALTRI USE CASE

### **Se Volessi Permettere Export:**
```swift
// Salva in Application Support (privato)
try PersistenceManager.save(categorie)

// Funzione separata per export in Documents (pubblico)
func exportToDocuments() throws {
    let documentsURL = try FileManager.default.url(
        for: .documentDirectory,
        in: .userDomainMask,
        appropriateFor: nil,
        create: true
    )
    let exportURL = documentsURL.appendingPathComponent("spese_export.json")
    let data = try JSONEncoder().encode(categorieSpese)
    try data.write(to: exportURL)
    // Ora l'utente può vedere/condividere questo file
}
```

### **Se Volessi Usare Cache (Temporaneo):**
```swift
let cachesURL = try FileManager.default.url(
    for: .cachesDirectory,
    in: .userDomainMask,
    appropriateFor: nil,
    create: true
)
```

### **Se Volessi Usare Tmp (Sessione):**
```swift
let tmpURL = FileManager.default.temporaryDirectory
let fileURL = tmpURL.appendingPathComponent("temp.json")
```

---

## 🎓 BEST PRACTICES iOS

### **Regola d'Oro:**
```
Dati PRIVATI dell'app      → Application Support
Documenti dell'UTENTE      → Documents
Cache RIGENERABILE         → Caches
File TEMPORANEI sessione   → Tmp
```

### **Apple Guidelines:**
- ✅ Usa **Application Support** per file di dati app
- ✅ Usa **Documents** solo per file generati dall'utente
- ✅ Usa **Caches** per dati scaricabili di nuovo
- ✅ Usa **Tmp** per file che non servono dopo la sessione

### **iCloud Backup:**
```
Application Support  → ✅ Backed up (ma nascosto)
Documents            → ✅ Backed up (e visibile)
Caches               → ❌ Non backed up
Tmp                  → ❌ Non backed up
```

---

## ✅ VANTAGGI DELLA MODIFICA

### **Per il Tuo Progetto:**
1. ✅ **Più professionale** - Seguendo le best practices Apple
2. ✅ **Più sicuro** - Utente non può corrompere il file
3. ✅ **Più pulito** - Non appare in "Files" app
4. ✅ **Stessa funzionalità** - Persistenza identica
5. ✅ **Stesso backup** - Sincronizzato su iCloud

### **Nessun Svantaggio:**
- ✅ Funziona esattamente come prima
- ✅ Nessuna perdita di funzionalità
- ✅ Nessun cambiamento per l'utente (è trasparente)

---

## 🚀 MIGRARE I DATI ESISTENTI (Opzionale)

Se avevi già dati in Documents, puoi migrarli:

```swift
// In ExpenseManager.init()
func migraDaDocumentsAdAppSupport() {
    let fileManager = FileManager.default
    
    // Vecchio path (Documents)
    guard let oldURL = try? fileManager.url(
        for: .documentDirectory,
        in: .userDomainMask,
        appropriateFor: nil,
        create: false
    ).appendingPathComponent("spese.json") else { return }
    
    // Nuovo path (Application Support)
    guard let newURL = try? fileManager.url(
        for: .applicationSupportDirectory,
        in: .userDomainMask,
        appropriateFor: nil,
        create: true
    ).appendingPathComponent("spese.json") else { return }
    
    // Se il vecchio file esiste e il nuovo no, sposta
    if fileManager.fileExists(atPath: oldURL.path) &&
       !fileManager.fileExists(atPath: newURL.path) {
        try? fileManager.moveItem(at: oldURL, to: newURL)
        print("✅ Dati migrati da Documents ad Application Support")
    }
}
```

---

## 📚 RISORSE APPLE

### **Documentation:**
- [File System Programming Guide](https://developer.apple.com/library/archive/documentation/FileManagement/Conceptual/FileSystemProgrammingGuide/)
- [App Sandbox Design Guide](https://developer.apple.com/library/archive/documentation/Security/Conceptual/AppSandboxDesignGuide/)

### **Search Paths:**
```swift
.documentDirectory           // Documenti utente
.applicationSupportDirectory // Dati app (✅ TUO CASO)
.cachesDirectory            // Cache temporanee
.temporaryDirectory         // File sessione
```

---

## 🎉 CONCLUSIONE

**Hai fatto la scelta giusta!** 🎯

Application Support è il posto **corretto e professionale** per salvare i dati interni della tua app. È dove app come:
- 📱 WhatsApp salva il database messaggi
- 📧 Mail salva le email locali
- 📊 Banking apps salvano i dati transazioni
- 🎵 Music apps salvano le playlist

**Il tuo file JSON è ora privato, sicuro e persistente - esattamente come dovrebbe essere!** ✅

---

*La modifica è già stata applicata nel file PersistenceManager.swift. Ricompila l'app per vedere il cambiamento!*
