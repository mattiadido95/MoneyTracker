# 🐛 DEBUG: App Crasha al Build & Run

## ❌ PROBLEMA RIPORTATO

```
Build → ⌘ + R → App si avvia → CRASH
```

---

## 🔧 FIX APPLICATI

### **1. Auto-Save Durante Init**

**Problema:**
Durante `init()`, quando `caricaDati()` assegna a `categorieSpese`, il `didSet` viene chiamato immediatamente e tenta di salvare, ma l'inizializzazione non è completa.

**Soluzione:**
```swift
init() {
    self.autoSaveEnabled = false  // ← Disabilita durante init
    caricaDati()
    calcolaTotali()
    self.autoSaveEnabled = true   // ← Riabilita dopo init
}
```

---

### **2. Logging Dettagliato**

**Aggiunto:**
- 🔵 Log durante `init()` standard
- 🟣 Log durante `init(mockData:)`
- Ogni step loggato per capire dove crasha

---

## 🧪 COME DEBUGGARE

### **Step 1: Verifica Console**

1. **Apri Console** in Xcode (⌘ + Shift + C)
2. **Run app** (⌘ + R)
3. **Leggi i log** nella sequenza:

```
🔵 ExpenseManager init() - START
🔵 Auto-save disabilitato temporaneamente
📂 Caricati X record  (oppure ℹ️ Nessuna spesa presente)
🔵 Dati caricati
🔵 Totali calcolati
🔵 Auto-save riabilitato
🔵 ExpenseManager init() - COMPLETE
```

**Se vedi tutti questi log**, l'init è OK.

**Se crasha prima**, vedrai dove si ferma.

---

### **Step 2: Identifica il Punto del Crash**

#### **Scenario A: Crash Prima di "START"**
```
(nessun log)
CRASH
```
**Problema:** ContentView o MoneyTrackerApp
**Verifica:** ContentView.swift, MoneyTrackerApp.swift

---

#### **Scenario B: Crash Durante "caricaDati"**
```
🔵 ExpenseManager init() - START
🔵 Auto-save disabilitato
CRASH
```
**Problema:** PersistenceManager.load()
**Verifica:** 
- Permessi filesystem
- Application Support directory
- JSON corrotto

**Fix:**
```swift
// In caricaDati()
do {
    let categorie = try PersistenceManager.load()
    categorieSpese = categorie
} catch {
    print("❌ ERRORE CARICAMENTO: \(error)")
    print("❌ Dettaglio: \(error.localizedDescription)")
    categorieSpese = []  // ← Fallback sicuro
}
```

---

#### **Scenario C: Crash Durante "calcolaTotali"**
```
🔵 Dati caricati
CRASH
```
**Problema:** Calcoli su dati invalidi
**Verifica:**
- Date invalide
- Importi NaN/Infinity
- Array corrotto

**Fix:**
```swift
private func calcolaTotali() {
    guard !categorieSpese.isEmpty else {
        print("⚠️ Nessuna spesa, calcoli skippati")
        return
    }
    // ... resto del codice
}
```

---

#### **Scenario D: Crash Dopo "COMPLETE"**
```
🔵 ExpenseManager init() - COMPLETE
CRASH
```
**Problema:** SwiftUI rendering o NavigationView
**Verifica:**
- HomeView.swift
- ContentView.swift
- Componenti UI

---

### **Step 3: Testa in Isolamento**

#### **Test A: ExpenseManager Solo**
```swift
// In MoneyTrackerApp.swift, temporaneamente:
@main
struct MoneyTrackerApp: App {
    var body: some Scene {
        WindowGroup {
            Text("Test")
                .onAppear {
                    let manager = ExpenseManager()
                    print("✅ Manager creato con successo")
                    print("📊 Spese: \(manager.categorieSpese.count)")
                }
        }
    }
}
```

Se questo funziona → problema nell'UI
Se crasha → problema in ExpenseManager

---

#### **Test B: ContentView Minimo**
```swift
// In ContentView.swift, temporaneamente:
struct ContentView: View {
    @StateObject private var expenseManager = ExpenseManager()
    
    var body: some View {
        Text("Spese: \(expenseManager.categorieSpese.count)")
    }
}
```

Se questo funziona → problema in HomeView/componenti
Se crasha → problema in ContentView

---

#### **Test C: HomeView Isolata**
```swift
// Commenta componenti uno alla volta:
var body: some View {
    ScrollView {
        VStack {
            // HeaderCard(...)  ← Commenta
            Text("Test 1")
            
            // AddExpenseButton { } ← Commenta
            Text("Test 2")
            
            // ... etc
        }
    }
}
```

Trova quale componente causa il crash.

---

## 🔍 CRASH COMUNI E FIX

### **1. "No ObservableObject found"**
```
Fatal error: No ObservableObject of type ExpenseManager found
```

**Causa:** EnvironmentObject mancante

**Fix:**
```swift
// Verifica che ContentView faccia:
NavigationView {
    HomeView()
        .environmentObject(expenseManager)  // ← Deve esserci!
}
```

---

### **2. "Cannot access file"**
```
Error: Cannot access Application Support directory
```

**Causa:** Permessi filesystem

**Fix:**
```swift
// In PersistenceManager.swift
private static func getFileURL() throws -> URL {
    do {
        let url = try FileManager.default.url(...)
        print("📁 File URL: \(url.path)")
        return url
    } catch {
        print("❌ ERRORE URL: \(error)")
        throw error
    }
}
```

---

### **3. "Invalid JSON"**
```
Error: The data couldn't be read because it isn't in the correct format
```

**Causa:** JSON corrotto

**Fix:**
```swift
// Elimina il file corrotto e ricrea
func resetDati() {
    try? PersistenceManager.deleteAll()
    categorieSpese = []
}

// Oppure in Simulator:
// 1. Stop app
// 2. Delete app (long press → Delete)
// 3. Run again
```

---

### **4. "Bad Access / EXC_BAD_ACCESS"**
```
Thread 1: EXC_BAD_ACCESS (code=1, address=0x...)
```

**Causa:** Memory issue, probabilmente didSet ricorsivo

**Fix Già Applicato:**
```swift
init() {
    self.autoSaveEnabled = false  // ← Previene didSet loop
    caricaDati()
    self.autoSaveEnabled = true
}
```

---

## 📋 CHECKLIST DEBUG

### **Verifica Base:**
- [ ] Console aperta (⌘ + Shift + C)
- [ ] Leggi tutti i log
- [ ] Identifica ultimo log prima del crash

### **Verifica Init:**
- [ ] Vedi "🔵 START"
- [ ] Vedi "🔵 Dati caricati"
- [ ] Vedi "🔵 COMPLETE"

### **Verifica Persistenza:**
- [ ] Menu "..." → "Info File"
- [ ] Verifica path è valido
- [ ] Verifica file esiste

### **Verifica UI:**
- [ ] HomeView si carica
- [ ] Componenti renderizzano
- [ ] No errori SwiftUI

---

## 🔧 FIX TEMPORANEI

### **Bypass Persistenza (Test)**
```swift
// In ExpenseManager.init()
init() {
    self.autoSaveEnabled = false
    // caricaDati()  ← Commenta temporaneamente
    // Carica dati mock per test
    caricaDatiMockPerPreview()
    calcolaTotali()
    self.autoSaveEnabled = true
}
```

Se l'app funziona così → problema in persistenza
Se ancora crasha → problema altrove

---

### **Bypass UI Componenti (Test)**
```swift
// In HomeView
var body: some View {
    ScrollView {
        VStack {
            Text("Test: \(expenseManager.categorieSpese.count) spese")
            // Commenta tutto il resto
        }
    }
}
```

Se funziona → problema in un componente specifico
Decommenta uno alla volta per trovare il colpevole

---

## 🎯 AZIONI IMMEDIATE

### **1. Esegui App e Leggi Console**
```bash
⌘ + R
⌘ + Shift + C  (apri console)
```

Copia l'ultimo log e il messaggio di errore completo.

---

### **2. Test Reset Completo**
```
1. Stop app
2. Simulator → Device → Erase All Content and Settings
3. ⌘ + R (Run)
```

Elimina ogni stato/cache precedente.

---

### **3. Verifica File JSON**
```
Menu "..." → "Info File"

Se path non appare → problema PersistenceManager
Se appare → file esiste, verifica contenuto
```

---

## 📊 INFO DA FORNIRE PER DEBUG

Se il problema persiste, fornisci:

1. **Console Output Completo**
   - Dal "START" fino al crash
   - Includi stack trace

2. **Ultimo Log Visibile**
   - Quale emoji? 🔵 o ⚠️ o ❌

3. **Messaggio Errore**
   - "Fatal error: ..."
   - "Thread X: ..."

4. **Cosa Stai Facendo**
   - Fresh install?
   - Dopo aver aggiunto spese?
   - Dopo reset dati?

5. **Versione iOS**
   - Simulator o Device?
   - iOS 17? 18?

---

## ✅ VERIFICHE FINALI

### **App Dovrebbe:**
- ✅ Avviarsi senza crash
- ✅ Mostrare dashboard vuota o con spese
- ✅ Permettere aggiunta spese
- ✅ Salvare automaticamente
- ✅ Persistere dopo chiusura

### **Console Dovrebbe Mostrare:**
```
🔵 ExpenseManager init() - START
🔵 Auto-save disabilitato temporaneamente
📂 Caricati X record
🔵 Dati caricati
🔵 Totali calcolati
🔵 Auto-save riabilitato
🔵 ExpenseManager init() - COMPLETE
```

---

## 🆘 SE NIENTE FUNZIONA

### **Nuclear Option: Reset Totale**

1. **Delete App dal Simulator**
2. **Clean Build Folder** (⌘ + Shift + K)
3. **Delete Derived Data**
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData
   ```
4. **Restart Xcode**
5. **Build & Run**

---

*Documenta l'ultimo log visibile e il messaggio di errore esatto per debug più preciso.*
