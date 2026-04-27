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
    
    /// Categorie supportate con keyword (basate sui merchant reali BPER)
    private let categoryRules: [String: [String]] = [

        // ── Alimentari ───────────────────────────────────────────────────────
        "Alimentari": [
            "supermercato", "alimentari", "drogheria",
            "conad", "coop ", "esselunga", "carrefour", "lidl",
            "eurospin", "aldi", "penny ", "pam ", "sigma ",
            "iper ", "ipercoop", "simply", "bennet", "unes",
            "coal ", "interspar", "unicoop",
            "ciampalini",                            // macelleria Pisa
            "macelleria", "panificio", "forno ", "mercato rionale"
        ],

        // ── Ristorazione ─────────────────────────────────────────────────────
        "Ristorazione": [
            "ristorante", "pizzeria", "trattoria", "osteria",
            "bar ", "caffe", "caffè", "pub ", "bistrot", "gelateria",
            "mcdonald", "mac donald", "burger king", "kfc", "subway",
            "old wild west", "autogrill",
            "sushi", "poke", "kitchen", "sali scendi",
            "dabbe", "beerholds", "coyote", "vapori di birra",
            "dreamcream", "giap ", "enodelizie",
            "deliveroo", "glovo", "just eat", "justeat", "uber eats"
        ],

        // ── Trasporti ────────────────────────────────────────────────────────
        "Trasporti": [
            "benzina", "gasolio", "carburante", "diesel",
            "autostrada", "pedaggio", "telepass",
            "treno", "trenitalia", "italo", "freccia",
            "metro ", "taxi", "uber ",
            "parcheggio", "sosta ",
            "aspit", "bspdv", "eniparki",
            "self nuova oasi", "sozio carburanti",
            "vomano ovest", "45515",                 // benzinaio Pisa via San Pietro

            "ip ", "agip", "q8 ", "esso ", "shell ", "tamoil"
        ],

        // ── Telecomunicazioni ────────────────────────────────────────────────
        "Telecomunicazioni": [
            "vodafone", "tim ", "wind ", "iliad", "fastweb", "tiscali",
            "adsl", "fibra", "sky ", "dazn",
            "bollettino postale"
        ],

        // ── Utenze ───────────────────────────────────────────────────────────
        "Utenze": [
            "enel ", "eni gas", "a2a", "hera ", "iren ", "acea ",
            "sorgenia", "engie", "plenitude",
            "bolletta luce", "bolletta gas", "bolletta acqua",
            "addebito sdd enel", "addebito sdd iren", "addebito sdd a2a",
            "addebito utenza"
        ],

        // ── Salute ───────────────────────────────────────────────────────────
        "Salute": [
            "farmacia", "parafarmacia", "farma ",
            "medico", "dottore", "ospedale", "clinica",
            "dentista", "odontoiatra",
            "analisi", "laboratorio", "ottica",
            "centro di medicina", "centro medico"
        ],

        // ── Animali ──────────────────────────────────────────────────────────
        "Animali": [
            "zooing", "arcaplanet", "zoonove",
            "veterinario", "centro veterinario",
            "green fish", "cinofilo",
            "petshop", "pet shop"
        ],

        // ── Affitto ──────────────────────────────────────────────────────────
        "Affitto": [
            "affitto", "locazione", "canone locazione",
            "condominio", "amministratore",
            "bozza venturi", "vicedomini"
        ],

        // ── Casa ─────────────────────────────────────────────────────────────
        "Casa": [
            "ikea", "leroy merlin", "brico", "bricocenter", "bricoman",
            "obi ", "castorama", "tigota",
            "arredamento", "mobili", "elettrodomestic",
            "ipershopping casa", "panda home", "kasanova"
        ],

        // ── Abbigliamento ────────────────────────────────────────────────────
        "Abbigliamento": [
            "zara", "h&m", "bershka", "pull&bear", "mango",
            "decathlon", "nike ", "adidas", "footlocker",
            "intimissimi", "calzedonia", "primark", "pepco",
            "abbigliamento", "calzature", "scarpe"
        ],

        // ── Intrattenimento ──────────────────────────────────────────────────
        "Intrattenimento": [
            "cinema", "teatro", "spettacolo", "concerto",
            "netflix", "spotify", "amazon prime", "disney", "apple tv",
            "playstation", "xbox", "steam",
            "palestra", "gym", "fitness", "piscina",
            "padel", "campo sportivo", "associazione sportiva", "asd "
        ],

        // ── Assicurazioni ────────────────────────────────────────────────────
        "Assicurazioni": [
            "alleanza assicurazioni", "generali", "allianz",
            "unipol", "sara assicurazioni", "zurich",
            "assicurazione", "polizza", "premio polizze"
        ],

        // ── Rate/Finanziamento ───────────────────────────────────────────────
        "Rate/Finanziamento": [
            "agos ducato", "compass banca", "findomestic",
            "cofidis", "santander consumer",
            "finanziamento", "rata mutuo", "mutuo", "prestito"
        ],

        // ── Spese Bancarie ───────────────────────────────────────────────────
        "Spese Bancarie": [
            "commissioni bonifici", "commissioni carta",
            "commissioni pagamento", "comm. su ric",
            "imposta di bollo", "competenze spese",
            "canone conto", "spese tenuta conto"
        ],

        // ── Tasse ────────────────────────────────────────────────────────────
        "Tasse": [
            "pagopa", "f24", "agenzia delle entrate",
            "tributo", "imu ", "tari ", "tasi "
        ],

        // ── Istruzione ───────────────────────────────────────────────────────
        "Istruzione": [
            "universita", "università", "ecampus", "e-campus",
            "scuola", "formazione", "tasse universitarie"
        ],

        // ── Viaggi ───────────────────────────────────────────────────────────
        "Viaggi": [
            "ryanair", "alitalia", "vueling", "easyjet", "wizz",
            "hotel", "airbnb", "booking.com",
            "traghetto", "crociera"
        ],

        // ── Stipendio ────────────────────────────────────────────────────────
        "Stipendio": [
            "emolumenti", "stipendio", "salario", "retribuzione",
            "accredito competenze", "accredito mensile",
            "iconsulting"
        ],

        // ── Prelievo ─────────────────────────────────────────────────────────
        "Prelievo": [
            "prelievo atm", "prelievo bancomat"
        ],

        // ── Carta Prepagata ──────────────────────────────────────────────────
        "Carta Prepagata": [
            "carta prepagata", "ric.prep.", "ricarica prepagata",
            "smart web mobile"
        ],

        // ── PayPal ───────────────────────────────────────────────────────────
        "PayPal": [
            "paypal"
        ]
    ]

    /// Categorie BPER "specifiche": se keyword matching non trova nulla,
    /// queste valgono come fallback affidabile.
    /// "PAGAMENTO" e "BANCOMAT" esclusi: troppo generici.
    private let bperSpecificCategories: Set<String> = [
        "Prelievo", "Bonifico", "Stipendio", "Utenze", "Tasse", "Mutuo"
    ]
    
    /// History di feedback per learning (simulato)
    private var feedbackHistory: [(description: String, category: String)] = []
    
    // MARK: - CategoryResolver Conformance
    
    var supportsLearning: Bool {
        true
    }
    
    func resolveCategory(for transaction: BankTransaction) async -> CategoryResolutionResult {
        let description = transaction.description.lowercased()
        let counterparty = transaction.counterparty?.lowercased() ?? ""
        let searchText = "\(description) \(counterparty)"

        // 1. Feedback history ha priorità massima (scelta esplicita dell'utente)
        if let historicalCategory = findInHistory(searchText) {
            return .certain(
                category: historicalCategory,
                method: .userHistory,
                reasoning: "Categoria appresa da precedenti feedback"
            )
        }

        // 2. Keyword matching sulla descrizione
        var matches: [(category: String, matchCount: Int, keywords: [String])] = []
        for (category, keywords) in categoryRules {
            let matchedKeywords = keywords.filter { searchText.contains($0) }
            if !matchedKeywords.isEmpty {
                matches.append((category, matchedKeywords.count, matchedKeywords))
            }
        }

        if !matches.isEmpty {
            matches.sort { $0.matchCount > $1.matchCount }
            let best = matches[0]
            let second = matches.count > 1 ? matches[1] : nil

            var confidence: Double
            if best.matchCount >= 3       { confidence = 0.95 }
            else if best.matchCount == 2  { confidence = 0.85 }
            else if second == nil         { confidence = 0.75 }
            else                          { confidence = 0.55 }

            if let s = second, s.matchCount == best.matchCount { confidence *= 0.7 }

            let matchRatio = Double(best.matchCount)
            let alternatives = matches.dropFirst().prefix(2).map { match in
                (match.category, confidence * (Double(match.matchCount) / matchRatio) * 0.8)
            }

            return CategoryResolutionResult(
                category: best.category,
                confidence: confidence,
                method: .ruleBased,
                alternatives: Array(alternatives),
                reasoning: "Match keyword: \(best.keywords.joined(separator: ", "))"
            )
        }

        // 3. Nessuna keyword trovata:
        //    - Se la categoria della banca è "specifica" (es. Prelievo, Bonifico) → usala
        //    - Se è generica (es. "Pagamento") → fallback a "Spese Varie"
        if let bankCategory = transaction.category,
           bperSpecificCategories.contains(bankCategory) {
            return .uncertain(
                category: bankCategory,
                confidence: 0.65,
                method: .ruleBased,
                reasoning: "Nessuna keyword: uso categoria banca '\(bankCategory)'"
            )
        }

        let defaultCategory = transaction.type == .income ? "Stipendio" : "Spese Varie"
        return .uncertain(
            category: defaultCategory,
            confidence: 0.2,
            method: .ruleBased,
            reasoning: "Nessuna keyword riconosciuta"
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
