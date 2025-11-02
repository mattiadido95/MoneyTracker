# 💰 MoneyTracker - Guida Completa Swift & SwiftUI

Una guida completa per imparare Swift e SwiftUI attraverso un progetto reale di gestione spese.

## 📋 Indice

- [🎯 Panoramica del Progetto](#-panoramica-del-progetto)
- [🏗️ Architettura dell'App](#️-architettura-dellapp)
- [📁 Struttura del Progetto](#-struttura-del-progetto)
- [🧩 Componenti Principali](#-componenti-principali)
- [📚 Concetti Swift Fondamentali](#-concetti-swift-fondamentali)
- [🎨 Concetti SwiftUI Essenziali](#-concetti-swiftui-essenziali)
- [🔄 Pattern Architetturali](#-pattern-architetturali)
- [💡 Concetti Avanzati](#-concetti-avanzati)
- [🚀 Prossimi Passi](#-prossimi-passi)

---

## 🎯 Panoramica del Progetto

**MoneyTracker** è un'app iOS per la gestione delle spese personali che implementa i pattern e le best practices moderne di SwiftUI. È perfetta per imparare Swift perché utilizza:

- ✅ **MVVM Architecture** - Separazione chiara delle responsabilità
- ✅ **SwiftUI Declarative UI** - Interface moderna e reattiva
- ✅ **Combine Framework** - Gestione reattiva dei dati
- ✅ **Component-Based Design** - Riutilizzo e modularità
- ✅ **Modern Swift** - Linguaggio aggiornato e idiomatico

---

## 🏗️ Architettura dell'App

```
┌─────────────────────────────────────────┐
│             MoneyTrackerApp              │  ← Entry Point (@main)
│                 @main                   │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│              ContentView                │  ← Root Container
│              @StateObject               │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│              HomeView                   │  ← Main Dashboard
│           @EnvironmentObject            │
└─────┬─────┬─────┬─────────────┬─────────┘
      │     │     │             │
      ▼     ▼     ▼             ▼
┌─────────┬─────────┬─────────┬─────────┐
│HeaderCard│AddButton│SummaryGrid│Categories│  ← UI Components
└─────────┴─────────┴─────────┴─────────┘
```

### 🔄 Flusso dei Dati (Data Flow)

```
ExpenseManager (ViewModel) 
       ↓ @Published properties
   ContentView (@StateObject)
       ↓ .environmentObject()
    HomeView (@EnvironmentObject)
       ↓ Parameters
  UI Components (Read-Only)
```

---

## 📁 Struttura del Progetto

```
MoneyTracker/
├── 📱 App Entry Point
│   ├── MoneyTrackerApp.swift      # @main entry point
│   └── ContentView.swift          # Root view container
│
├── 🎛️ ViewModels  
│   └── ExpenseManager.swift       # Business logic & data
│
├── 🏠 Main Views
│   └── HomeView.swift            # Dashboard orchestrator
│
├── 🧩 UI Components
│   ├── HeaderCard.swift          # Hero section
│   ├── AddExpenseButton.swift    # Primary CTA
│   ├── SummaryCard.swift         # Reusable metric card
│   ├── SummaryCardsGrid.swift    # Grid layout
│   ├── CategoriesSection.swift   # Categories container
│   └── CategoryRow.swift         # Single category item
│
└── 📊 Models
    └── CategoriaSpesa.swift      # Data structure
```

---

## 🧩 Componenti Principali

### 1. 📱 **MoneyTrackerApp** - Entry Point
```swift
@main struct MoneyTrackerApp: App
```

**Concetti Swift:**
- `@main` attribute
- `App` protocol
- `WindowGroup` scene
- Application lifecycle

**Responsabilità:**
- Punto di ingresso dell'app
- Configurazione globale
- Gestione delle Scene

---

### 2. 🏠 **ContentView** - Root Container
```swift
struct ContentView: View {
    @StateObject private var expenseManager = ExpenseManager()
}
```

**Concetti Swift/SwiftUI:**
- `@StateObject` vs `@ObservedObject`
- Dependency Injection pattern
- `NavigationView` container
- Environment object distribution

**Responsabilità:**
- Creazione del ViewModel condiviso
- Configurazione della navigazione
- Distribuzione delle dipendenze

---

### 3. 🧠 **ExpenseManager** - ViewModel/Business Logic
```swift
class ExpenseManager: ObservableObject {
    @Published var totaleMensile: Double
    @Published var categorieSpese: [CategoriaSpesa]
}
```

**Concetti Swift:**
- `class` vs `struct` (Reference vs Value types)
- `ObservableObject` protocol
- `@Published` property wrapper
- Combine framework integration
- Private methods and encapsulation

**Responsabilità:**
- Gestione stato dell'applicazione
- Business logic calculations
- Data persistence (future)
- UI notifications via Combine

---

### 4. 🎨 **HomeView** - Dashboard Orchestrator
```swift
struct HomeView: View {
    @EnvironmentObject var expenseManager: ExpenseManager
}
```

**Concetti SwiftUI:**
- `@EnvironmentObject` dependency injection
- `ScrollView` and responsive layout
- `VStack` with spacing
- Navigation configuration
- Container-Presenter pattern

**Responsabilità:**
- Layout composition
- Component coordination
- Data distribution to children

---

### 5. 🧩 **UI Components** - Modular Interface

#### **HeaderCard** - Hero Component
- Font hierarchy (`headline`, `title`, `caption`)
- Color semantics (`primary`, `secondary`)
- Layout composition (`HStack`, `VStack`)

#### **SummaryCard** - Reusable Component
- Parametric design
- SF Symbols integration
- Adaptive text sizing
- Component reusability

#### **CategoryRow** - List Item
- Computed properties
- Color coding
- Percentage calculations
- Single responsibility principle

---

## 📚 Concetti Swift Fondamentali

### 1. **Types System**

#### **Value Types (struct)**
```swift
struct CategoriaSpesa {        // Copied when assigned
    let nome: String
    let importo: Double
    let colore: Color
}
```

#### **Reference Types (class)**
```swift
class ExpenseManager {         // Shared reference when assigned
    @Published var data: [Item]
}
```

### 2. **Property Wrappers**
```swift
@StateObject private var manager = ExpenseManager()    // Creates & owns
@EnvironmentObject var manager: ExpenseManager        // Receives from environment  
@Published var totaleMensile: Double                  // Notifies on change
```

### 3. **Access Control**
```swift
private var data: [Item]       // Only within this file
internal var data: [Item]      // Default - within module
public var data: [Item]        // Accessible from other modules
```

### 4. **Computed Properties**
```swift
var percentuale: Double {
    (categoria.importo / totale) * 100    // Calculated on access
}
```

### 5. **Closures & Functions**
```swift
let action: () -> Void         // Closure type
Button(action: action) { }     // Closure as parameter
```

---

## 🎨 Concetti SwiftUI Essenziali

### 1. **Views & Modifiers**
```swift
Text("Hello")
    .font(.headline)           // View modifier
    .foregroundColor(.blue)    // Method chaining
    .padding()                // Layout modifier
```

### 2. **Layout System**
```swift
VStack(spacing: 20) {         // Vertical stack
    HStack {                  // Horizontal stack
        Text("Left")
        Spacer()              // Flexible space
        Text("Right")
    }
}
```

### 3. **State Management**
```swift
// Local state
@State private var isVisible = true

// Shared state
@StateObject private var manager = DataManager()

// Inherited state  
@EnvironmentObject var manager: DataManager
```

### 4. **Data Flow**
```swift
// Parent → Child (Down)
ChildView(data: parentData)

// Child → Parent (Up)  
Button("Action") { parentAction() }
```

### 5. **Lists & Collections**
```swift
ForEach(items, id: \.id) { item in
    ItemRow(item: item)        // Dynamic view creation
}
```

---

## 🔄 Pattern Architetturali

### 1. **MVVM (Model-View-ViewModel)**

```
Model (CategoriaSpesa)
  ↑
ViewModel (ExpenseManager) ← ObservableObject
  ↑ @Published
View (HomeView) ← @EnvironmentObject
```

**Vantaggi:**
- Separazione delle responsabilità
- Testabilità migliorata  
- Riusabilità del business logic
- Data binding automatico

### 2. **Unidirectional Data Flow**

```
Data flows DOWN ↓
    [Parent]
       ↓ props
   [Child View]

Actions flow UP ↑  
   [Child View]
       ↑ callbacks
    [Parent]
```

### 3. **Composition over Inheritance**
```swift
// ✅ Good - Composition
struct HomeView: View {
    var body: some View {
        VStack {
            HeaderCard()      // Composed components
            SummaryGrid()
            CategoriesList()
        }
    }
}

// ❌ Avoid - Inheritance
class BaseViewController: UIViewController { ... }
class HomeViewController: BaseViewController { ... }
```

### 4. **Dependency Injection**
```swift
// Service creation
@StateObject private var expenseManager = ExpenseManager()

// Service distribution
HomeView()
    .environmentObject(expenseManager)

// Service consumption
@EnvironmentObject var expenseManager: ExpenseManager
```

---

## 💡 Concetti Avanzati

### 1. **Combine Framework**
```swift
import Combine

class ExpenseManager: ObservableObject {
    @Published var totaleMensile: Double = 0.0    // Publisher
    
    // Subscribers get notified automatically
    // UI updates happen on main thread
}
```

### 2. **SwiftUI Lifecycle**
```swift
struct ContentView: View {
    @StateObject private var manager = ExpenseManager()
    
    // manager is created once and persists
    // Views can be recreated, but manager survives
}
```

### 3. **Memory Management**
```swift
// Value types (struct) - Automatic memory management
struct CategoriaSpesa { }    // Stack allocated, auto-deallocated

// Reference types (class) - ARC (Automatic Reference Counting)  
class ExpenseManager { }     // Heap allocated, ref counting
```

### 4. **Type Inference**
```swift
let name = "MoneyTracker"           // Inferred: String
let amount = 123.45                 // Inferred: Double
let categories: [CategoriaSpesa] = [] // Explicit typing
```

### 5. **Optional Handling**
```swift
// Safe unwrapping
if let category = categories.first {
    print(category.nome)
}

// Nil coalescing
let name = category?.nome ?? "Unknown"
```

---

## 🎯 Best Practices Implementate

### 1. **Component Design**
- ✅ Single Responsibility Principle
- ✅ Reusable and composable components
- ✅ Clear parameter interfaces
- ✅ Separation of concerns

### 2. **State Management**
- ✅ Unidirectional data flow
- ✅ Single source of truth
- ✅ Reactive updates via Combine
- ✅ Proper state ownership

### 3. **Code Organization**
- ✅ Logical file structure
- ✅ Clear naming conventions
- ✅ Comprehensive documentation
- ✅ Separation of UI and business logic

### 4. **Performance**
- ✅ Lazy loading with `LazyVGrid`
- ✅ Efficient view updates
- ✅ Proper use of `@StateObject` vs `@ObservedObject`
- ✅ Minimal view recomputation

---

## 📖 Glossario Termini Swift/SwiftUI

| Termine | Definizione | Esempio |
|---------|-------------|---------|
| **@StateObject** | Crea e possiede un ObservableObject | `@StateObject private var manager = Manager()` |
| **@EnvironmentObject** | Riceve un oggetto dall'environment | `@EnvironmentObject var manager: Manager` |
| **@Published** | Notifica le view dei cambiamenti | `@Published var data: [Item] = []` |
| **ObservableObject** | Protocollo per oggetti osservabili | `class Manager: ObservableObject` |
| **View Protocol** | Contratto per tutti i componenti UI | `struct MyView: View` |
| **ViewModifier** | Trasforma l'aspetto di una view | `.font(.headline)` |
| **Computed Property** | Proprietà calcolata dinamicamente | `var total: Double { ... }` |
| **Closure** | Blocco di codice anonimo | `{ print("Hello") }` |

---

## 🚀 Prossimi Passi per l'Apprendimento

### 1. **Livello Base** ✅ (Completato nel progetto)
- [x] Sintassi Swift base
- [x] SwiftUI views e layout
- [x] State management
- [x] Component composition

### 2. **Livello Intermedio** 🔄 (Parzialmente implementato)
- [ ] Navigation e routing
- [ ] Form handling e input validation
- [ ] Custom view modifiers
- [ ] Animation e transitions

### 3. **Livello Avanzato** 🎯 (Da implementare)
- [ ] Data persistence (Core Data/SwiftData)
- [ ] Network calls e API integration
- [ ] Error handling avanzato
- [ ] Testing (Unit & UI tests)
- [ ] Performance optimization

### 4. **Funzionalità da Aggiungere**
```swift
// AddExpenseView - Form per aggiungere spese
struct AddExpenseView: View {
    @State private var amount: String = ""
    @State private var category: String = ""
    @State private var date = Date()
}

// SettingsView - Configurazioni app
struct SettingsView: View {
    @AppStorage("darkMode") private var isDarkMode = false
}

// DetailView - Dettagli categoria
struct CategoryDetailView: View {
    let category: CategoriaSpesa
    // Lista delle singole transazioni
}
```

---

## 📚 Risorse per Approfondire

### **Apple Documentation**
- [SwiftUI Tutorials](https://developer.apple.com/tutorials/swiftui)
- [Swift Language Guide](https://docs.swift.org/swift-book/)
- [Combine Framework](https://developer.apple.com/documentation/combine)

### **Pattern & Architecture**
- MVVM in SwiftUI
- Combine reactive programming
- SwiftUI data flow
- iOS Human Interface Guidelines

### **Advanced Topics**
- SwiftData per persistence
- CloudKit integration
- WidgetKit extensions
- App Clips

---

## 🏆 Progetto Completato - Competenze Acquisite

Completando questo progetto hai imparato:

✅ **Swift Fundamentals**
- Types system (value vs reference)
- Property wrappers
- Access control
- Closures and functions

✅ **SwiftUI Essentials**  
- Declarative UI paradigm
- View composition and modifiers
- Layout system (stacks, grids)
- State management patterns

✅ **Architecture Patterns**
- MVVM implementation
- Dependency injection
- Unidirectional data flow
- Component-based design

✅ **iOS Development**
- App lifecycle and entry points
- Navigation patterns
- Design system implementation
- Platform conventions

---

**🎉 Congratulazioni! Hai una solida base per sviluppare app iOS moderne con Swift e SwiftUI!**

---

*Questo README serve come guida di studio. Ogni concetto è implementato nei file del progetto con documentazione dettagliata.*