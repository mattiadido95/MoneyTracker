//
//  CategoryResolver.swift
//  MoneyTracker
//
//  Created by Assistant on 14/12/25.
//

/*
 PROTOCOL - Category Resolver
 
 Responsabilità: Inferire categoria da BankTransaction
 
 DESIGN:
 • Protocol-oriented per permettere diverse implementazioni
 • Supporto AI, rule-based, hybrid
 • Confidenza (0.0-1.0) per quality indicator
 • Async per supportare chiamate API/ML model
 
 UTILIZZO:
 let resolver = MockCategoryResolver()
 let result = await resolver.resolveCategory(for: transaction)
 
 if result.confidence > 0.7 {
     print("Categoria: \(result.category) (confidenza: \(result.confidence))")
 }
*/

import Foundation

// MARK: - Category Resolution Result

/// Risultato della categorizzazione
struct CategoryResolutionResult {
    /// Categoria suggerita
    let category: String
    
    /// Confidenza (0.0 - 1.0)
    /// - 0.0-0.3: Bassa confidenza (guess)
    /// - 0.3-0.7: Media confidenza (probabile)
    /// - 0.7-1.0: Alta confidenza (certo)
    let confidence: Double
    
    /// Metodo usato per risoluzione
    let method: ResolutionMethod
    
    /// Categorie alternative (opzionale)
    let alternatives: [(category: String, confidence: Double)]
    
    /// Reasoning/spiegazione (per debugging/UI)
    let reasoning: String?
    
    // MARK: - Computed Properties
    
    /// Livello di confidenza come enum
    var confidenceLevel: ConfidenceLevel {
        switch confidence {
        case 0.0..<0.3:
            return .low
        case 0.3..<0.7:
            return .medium
        case 0.7...1.0:
            return .high
        default:
            return .unknown
        }
    }
    
    /// Suggerimento affidabile (confidence >= 0.7)
    var isReliable: Bool {
        confidence >= 0.7
    }
    
    /// Necessita review umano (confidence < 0.5)
    var needsHumanReview: Bool {
        confidence < 0.5
    }
    
    // MARK: - Convenience Initializers
    
    /// Crea risultato con categoria certa
    static func certain(
        category: String,
        method: ResolutionMethod,
        reasoning: String? = nil
    ) -> CategoryResolutionResult {
        CategoryResolutionResult(
            category: category,
            confidence: 1.0,
            method: method,
            alternatives: [],
            reasoning: reasoning
        )
    }
    
    /// Crea risultato con bassa confidenza
    static func uncertain(
        category: String,
        confidence: Double,
        method: ResolutionMethod,
        alternatives: [(String, Double)] = [],
        reasoning: String? = nil
    ) -> CategoryResolutionResult {
        CategoryResolutionResult(
            category: category,
            confidence: confidence,
            method: method,
            alternatives: alternatives,
            reasoning: reasoning
        )
    }
}

// MARK: - Resolution Method

/// Metodo usato per risolvere categoria
enum ResolutionMethod: String {
    case ruleBased = "Rule-Based"          // Keyword matching
    case machineLearning = "ML Model"      // AI/ML model
    case userHistory = "User History"      // Learning da utente
    case hybrid = "Hybrid"                 // Combinazione metodi
    case manual = "Manual"                 // Assegnata manualmente
    case unknown = "Unknown"               // Metodo non specificato
}

// MARK: - Confidence Level

/// Livello di confidenza categorizzato
enum ConfidenceLevel: String {
    case low = "Bassa"
    case medium = "Media"
    case high = "Alta"
    case unknown = "Sconosciuta"
    
    var emoji: String {
        switch self {
        case .low: return "🔶"
        case .medium: return "🟡"
        case .high: return "🟢"
        case .unknown: return "⚪️"
        }
    }
}

// MARK: - Category Resolver Protocol

/// Protocol per risolutori di categoria
protocol CategoryResolver {
    /// Risolve categoria per una transazione
    /// - Parameter transaction: Transazione da categorizzare
    /// - Returns: Risultato con categoria e confidenza
    func resolveCategory(for transaction: BankTransaction) async -> CategoryResolutionResult
    
    /// Risolve categorie per multiple transazioni
    /// - Parameter transactions: Array di transazioni
    /// - Returns: Array di risultati
    func resolveCategories(for transactions: [BankTransaction]) async -> [CategoryResolutionResult]
    
    /// Indica se il resolver supporta learning da feedback utente
    var supportsLearning: Bool { get }
    
    /// Feedback su una categorizzazione (per training)
    /// - Parameters:
    ///   - transaction: Transazione categorizzata
    ///   - category: Categoria corretta scelta da utente
    func provideFeedback(transaction: BankTransaction, correctCategory: String) async
}

// MARK: - Default Implementations

extension CategoryResolver {
    /// Implementazione default per batch resolution
    func resolveCategories(for transactions: [BankTransaction]) async -> [CategoryResolutionResult] {
        var results: [CategoryResolutionResult] = []
        
        for transaction in transactions {
            let result = await resolveCategory(for: transaction)
            results.append(result)
        }
        
        return results
    }
    
    /// Default: nessun learning
    var supportsLearning: Bool {
        false
    }
    
    /// Default: ignora feedback
    func provideFeedback(transaction: BankTransaction, correctCategory: String) async {
        // No-op by default
    }
}

// MARK: - Mock Category Resolver

/// Implementazione mock basata su keyword matching
class MockCategoryResolver: CategoryResolver {
    
    // MARK: - Properties
    
    /// Categorie supportate con keyword
    private let categoryRules: [String: [String]] = [
        "Utenze": [
            "luce", "gas", "acqua", "elettricità", "energia",
            "enel", "eni", "acea", "hera", "a2a",
            "bolletta", "consumo"
        ],
        "Telecomunicazioni": [
            "telefono", "internet", "mobile", "cellulare",
            "tim", "vodafone", "wind", "tre", "iliad", "fastweb",
            "adsl", "fibra", "ricarica"
        ],
        "Trasporti": [
            "benzina", "gasolio", "carburante", "diesel",
            "autostrada", "pedaggio", "telepass",
            "treno", "trenitalia", "italo", "metro", "bus",
            "taxi", "uber", "parcheggio", "multa"
        ],
        "Alimentari": [
            "supermercato", "spesa", "alimentari",
            "conad", "coop", "esselunga", "carrefour", "lidl", "eurospin",
            "pam", "sigma", "iper", "mercato"
        ],
        "Ristorazione": [
            "ristorante", "pizzeria", "trattoria", "osteria",
            "bar", "caffè", "pub", "bistrot",
            "mcdonald", "burger", "kfc", "subway",
            "deliveroo", "glovo", "just eat", "uber eats"
        ],
        "Salute": [
            "farmacia", "parafarmacia", "medico", "dottore",
            "ospedale", "clinica", "dentista", "odontoiatra",
            "visita", "analisi", "esame", "radiografia",
            "medicina", "farmaco"
        ],
        "Affitto": [
            "affitto", "rent", "locazione", "canone",
            "condominio", "amministratore"
        ],
        "Intrattenimento": [
            "cinema", "teatro", "spettacolo", "concerto",
            "netflix", "spotify", "amazon prime", "disney",
            "playstation", "xbox", "steam", "gaming",
            "palestra", "gym", "fitness"
        ],
        "Abbigliamento": [
            "zara", "h&m", "decathlon", "nike", "adidas",
            "abbigliamento", "vestiti", "scarpe", "calzature"
        ],
        "Casa": [
            "ikea", "leroy merlin", "brico", "fai da te",
            "arredamento", "mobili", "elettrodomestico"
        ],
        "Stipendio": [
            "stipendio", "salary", "salario", "retribuzione",
            "accredito", "bonifico stipendio", "cedolino"
        ],
        "Bonifico": [
            "bonifico", "trasferimento", "giroconto"
        ],
        "Prelievo": [
            "prelievo", "bancomat", "atm", "cash"
        ]
    ]
    
    /// History di feedback per learning (simulato)
    private var feedbackHistory: [(description: String, category: String)] = []
    
    // MARK: - CategoryResolver Conformance
    
    var supportsLearning: Bool {
        true
    }
    
    func resolveCategory(for transaction: BankTransaction) async -> CategoryResolutionResult {
        // Se ha già una categoria, restituiscila con confidenza alta
        if let existingCategory = transaction.category {
            return .certain(
                category: existingCategory,
                method: .manual,
                reasoning: "Categoria già presente nella transazione"
            )
        }
        
        let description = transaction.description.lowercased()
        let counterparty = transaction.counterparty?.lowercased() ?? ""
        let searchText = "\(description) \(counterparty)"
        
        // 1. Cerca match esatto in feedback history
        if let historicalCategory = findInHistory(searchText) {
            return .certain(
                category: historicalCategory,
                method: .userHistory,
                reasoning: "Categoria appresa da precedenti feedback"
            )
        }
        
        // 2. Cerca match con keyword rules
        var matches: [(category: String, matchCount: Int, keywords: [String])] = []
        
        for (category, keywords) in categoryRules {
            let matchedKeywords = keywords.filter { keyword in
                searchText.contains(keyword)
            }
            
            if !matchedKeywords.isEmpty {
                matches.append((category, matchedKeywords.count, matchedKeywords))
            }
        }
        
        // 3. Calcola confidenza basata su match
        if matches.isEmpty {
            // Nessun match: categoria generica con bassa confidenza
            let defaultCategory = transaction.type == .income ? "Entrate Varie" : "Spese Varie"
            return .uncertain(
                category: defaultCategory,
                confidence: 0.2,
                method: .ruleBased,
                reasoning: "Nessuna keyword riconosciuta"
            )
        }
        
        // Ordina per numero di match
        matches.sort { $0.matchCount > $1.matchCount }
        
        let bestMatch = matches[0]
        let secondBest = matches.count > 1 ? matches[1] : nil
        
        // Calcola confidenza
        var confidence: Double
        let matchRatio = Double(bestMatch.matchCount)
        
        if bestMatch.matchCount >= 3 {
            confidence = 0.95  // Molte keyword → alta confidenza
        } else if bestMatch.matchCount == 2 {
            confidence = 0.85  // Due keyword → buona confidenza
        } else if bestMatch.matchCount == 1 && secondBest == nil {
            confidence = 0.75  // Una keyword, nessuna alternativa
        } else if bestMatch.matchCount == 1 && secondBest != nil {
            confidence = 0.55  // Una keyword, ma ci sono alternative
        } else {
            confidence = 0.4   // Incerto
        }
        
        // Aggiusta confidenza se ci sono match competitivi
        if let secondBest = secondBest, secondBest.matchCount == bestMatch.matchCount {
            confidence *= 0.7  // Riduci confidenza se ambiguo
        }
        
        // Crea alternative
        let alternatives = matches.dropFirst().prefix(2).map { match in
            let altConfidence = confidence * (Double(match.matchCount) / matchRatio) * 0.8
            return (match.category, altConfidence)
        }
        
        let reasoning = "Match keyword: \(bestMatch.keywords.joined(separator: ", "))"
        
        return CategoryResolutionResult(
            category: bestMatch.category,
            confidence: confidence,
            method: .ruleBased,
            alternatives: Array(alternatives),
            reasoning: reasoning
        )
    }
    
    func provideFeedback(transaction: BankTransaction, correctCategory: String) async {
        // Memorizza feedback per future categorizzazioni
        feedbackHistory.append((
            description: transaction.description.lowercased(),
            category: correctCategory
        ))
        
        print("📚 Feedback memorizzato: '\(transaction.description)' → '\(correctCategory)'")
    }
    
    // MARK: - Private Methods
    
    private func findInHistory(_ searchText: String) -> String? {
        // Cerca match esatto in feedback history
        for (description, category) in feedbackHistory {
            if searchText.contains(description) || description.contains(searchText) {
                return category
            }
        }
        return nil
    }
}

// MARK: - Testing Helpers

#if DEBUG
extension MockCategoryResolver {
    /// Resolver pre-popolato con feedback per testing
    static var withHistory: MockCategoryResolver {
        let resolver = MockCategoryResolver()
        
        // Simula feedback storico
        Task {
            let mockTransaction1 = BankTransaction(
                date: Date(),
                amount: 50,
                type: .expense,
                description: "Esselunga Via Roma",
                bankSource: "Test"
            )
            await resolver.provideFeedback(transaction: mockTransaction1, correctCategory: "Alimentari")
            
            let mockTransaction2 = BankTransaction(
                date: Date(),
                amount: 30,
                type: .expense,
                description: "Netflix Abbonamento",
                bankSource: "Test"
            )
            await resolver.provideFeedback(transaction: mockTransaction2, correctCategory: "Intrattenimento")
        }
        
        return resolver
    }
}

extension CategoryResolutionResult {
    /// Risultato mock per preview
    static var mockHigh: CategoryResolutionResult {
        CategoryResolutionResult(
            category: "Utenze",
            confidence: 0.95,
            method: .ruleBased,
            alternatives: [
                ("Casa", 0.65),
                ("Spese Varie", 0.30)
            ],
            reasoning: "Match keyword: luce, bolletta, enel"
        )
    }
    
    static var mockMedium: CategoryResolutionResult {
        CategoryResolutionResult(
            category: "Alimentari",
            confidence: 0.55,
            method: .ruleBased,
            alternatives: [
                ("Ristorazione", 0.45)
            ],
            reasoning: "Match keyword: spesa"
        )
    }
    
    static var mockLow: CategoryResolutionResult {
        CategoryResolutionResult(
            category: "Spese Varie",
            confidence: 0.20,
            method: .ruleBased,
            alternatives: [],
            reasoning: "Nessuna keyword riconosciuta"
        )
    }
}
#endif

// MARK: - Extensions

extension CategoryResolutionResult: CustomStringConvertible {
    var description: String {
        let confidenceStr = String(format: "%.0f%%", confidence * 100)
        return "[\(method.rawValue)] \(category) (confidenza: \(confidenceStr))"
    }
}
