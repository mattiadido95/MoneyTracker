# ✅ FIX: Preview ExpenseManager Non Trovato

## ❌ ERRORE

```
Thread 1: Fatal error: No ObservableObject of type ExpenseManager found.
A View.environmentObject(_:) for ExpenseManager may be missing as an ancestor of this view.
```

**Dove appariva:**
- ExpenseListView preview
- AddExpenseView preview  
- CategoriesSection preview
- Qualsiasi altra view con `@EnvironmentObject var expenseManager`

---

## 🎯 CAUSA

Le preview usavano:
```swift
.environmentObject(ExpenseManager())  // ❌ PROBLEMA
```

Questo chiamava `init()` standard che:
1. Tenta di accedere al filesystem
2. Può crashare in preview mode
3. Anche se non crasha, non ha dati da mostrare

---

## ✅ SOLUZIONE

Usare il nuovo initializer con mock data:
```swift
.environmentObject(ExpenseManager(mockData: true))  // ✅ CORRETTO
```

---

## 🔧 FILE CORRETTI

### **1. ExpenseListView.swift** ✅

**Prima:**
```swift
struct ExpenseListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ExpenseListView()
                .environmentObject(ExpenseManager())  // ❌
        }
    }
}
```

**Dopo:**
```swift
struct ExpenseListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ExpenseListView()
                .environmentObject(ExpenseManager(mockData: true))  // ✅
        }
    }
}
```

---

### **2. AddExpenseView.swift** ✅

**Prima:**
```swift
struct AddExpenseView_Previews: PreviewProvider {
    static var previews: some View {
        AddExpenseView()
            .environmentObject(ExpenseManager())  // ❌
    }
}
```

**Dopo:**
```swift
struct AddExpenseView_Previews: PreviewProvider {
    static var previews: some View {
        AddExpenseView()
            .environmentObject(ExpenseManager(mockData: true))  // ✅
    }
}
```

---

### **3. CategoriesSection.swift** ✅

**Prima:**
```swift
struct CategoriesSection_Previews: PreviewProvider {
    static var previews: some View {
        CategoriesSection(totaleMensile: 1250.50)
            .environmentObject(ExpenseManager())  // ❌
            .padding()
    }
}
```

**Dopo:**
```swift
struct CategoriesSection_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {  // ← Aggiunto per NavigationLink
            CategoriesSection(totaleMensile: 1250.50)
                .environmentObject(ExpenseManager(mockData: true))  // ✅
                .padding()
        }
    }
}
```

**Nota:** Aggiunto anche `NavigationView` perché CategoriesSection ora ha un `NavigationLink` al suo interno.

---

## 📊 CONFRONTO

| Aspetto | `ExpenseManager()` | `ExpenseManager(mockData: true)` |
|---------|-------------------|----------------------------------|
| **Filesystem** | ✅ Accede | ❌ No accesso |
| **Auto-Save** | ✅ Attivo | ❌ Disabilitato |
| **Dati** | Da file JSON | Mock in memoria |
| **Crash Risk** | ⚠️ Alto in preview | ✅ Zero |
| **Dati Visibili** | Dipende | ✅ Sempre 4 spese |

---

## 🎨 DATI NELLE PREVIEW

Con `ExpenseManager(mockData: true)`, ogni preview mostra:
```
📝 Affitto    €800.00
💡 Luce       €89.50
🔥 Gas        €156.20
🌐 Internet   €29.90
```

**Vantaggi:**
- ✅ Dati sempre consistenti
- ✅ Preview veloci
- ✅ No crash
- ✅ Facile testare UI

---

## 🧪 TEST PREVIEW

### **ExpenseListView:**
```
1. Apri ExpenseListView.swift
2. Canvas → Resume
3. ✅ Vedi 4 spese mock
4. ✅ Header mostra "Totale: €1,075.60"
5. ✅ Menu filtri funziona
```

### **AddExpenseView:**
```
1. Apri AddExpenseView.swift
2. Canvas → Resume
3. ✅ Form si carica correttamente
4. ✅ ColorPicker visibile
5. ✅ Nessun crash
```

### **CategoriesSection:**
```
1. Apri CategoriesSection.swift
2. Canvas → Resume
3. ✅ Lista categorie visibile
4. ✅ "Vedi Tutto" button funziona
5. ✅ NavigationLink previewabile
```

---

## 📝 REGOLA GENERALE

**Per TUTTE le preview che usano ExpenseManager:**

```swift
// ❌ MAI fare questo in preview
.environmentObject(ExpenseManager())

// ✅ SEMPRE fare questo in preview
.environmentObject(ExpenseManager(mockData: true))
```

---

## 🔍 COME TROVARE ALTRI ERRORI

Cerca nel progetto:
```
.environmentObject(ExpenseManager())
```

Se trovi questa linea in un `PreviewProvider`, cambiala in:
```
.environmentObject(ExpenseManager(mockData: true))
```

---

## 💡 BEST PRACTICE PREVIEW

### **Template Base:**
```swift
struct MyView_Previews: PreviewProvider {
    static var previews: some View {
        MyView()
            .environmentObject(ExpenseManager(mockData: true))
    }
}
```

### **Con Navigation:**
```swift
struct MyView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            MyView()
                .environmentObject(ExpenseManager(mockData: true))
        }
    }
}
```

### **Con Dati Custom:**
```swift
struct MyView_Previews: PreviewProvider {
    static var previews: some View {
        let manager = ExpenseManager(mockData: true)
        
        // Modifica dati per test specifico
        manager.categorieSpese.append(
            CategoriaSpesa(nome: "Test", ...)
        )
        
        return MyView()
            .environmentObject(manager)
    }
}
```

### **Multiple Scenarios:**
```swift
struct MyView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            MyView()
                .environmentObject(ExpenseManager(mockData: true))
                .previewDisplayName("Con Dati")
            
            MyView()
                .environmentObject(ExpenseManager(mockData: false))
                .previewDisplayName("Vuoto")
        }
    }
}
```

---

## ✅ CHECKLIST FIX

### **Preview Corrette:**
- [x] ExpenseListView.swift
- [x] AddExpenseView.swift
- [x] CategoriesSection.swift
- [x] ContentView.swift (già fatto con wrapper)

### **Altre View (se necessario):**
- [ ] HomeView (se ha preview)
- [ ] HeaderCard (se ha preview)
- [ ] CategoryRow (se ha preview)
- [ ] SummaryCard (se ha preview)

---

## 🚨 RICORDA

### **In Preview:**
```swift
ExpenseManager(mockData: true)  // ✅ Usa SEMPRE
```

### **In Produzione (App):**
```swift
ExpenseManager()  // ✅ Usa SEMPRE
```

**MAI mescolarli!**

---

## 🎉 RISULTATO

**Prima:**
```
Preview → Fatal error: No ObservableObject ❌
Developer → Non posso testare UI 😤
```

**Dopo:**
```
Preview → Funziona con dati mock ✅
Developer → Test UI istantanei 😊
```

---

## 📚 FILE CORRELATI

- `ExpenseManager.swift` - Contiene `init(mockData:)`
- `FIX_PREVIEW_CRASH.md` - Documentazione completa fix
- Tutti i `*_Previews` - Ora usano mock data

---

*Fix completato: Tutte le preview ora usano ExpenseManager con mock data!* ✅
