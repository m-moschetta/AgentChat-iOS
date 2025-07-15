//
//  HybridMultiAgentService.swift
//  AgentChat
//
//  Created by Mario Moschetta on 04/07/25.
//

import Foundation
import Combine

// MARK: - HybridMultiAgentService
class HybridMultiAgentService: ChatServiceProtocol {
    static let shared = HybridMultiAgentService()
    
    private let coreAgents = CoreAgentSystem()
    private let remoteService = RemoteAgentService()
    private let responseCache = ResponseCache()
    
    private init() {}
    
    // MARK: - ChatServiceProtocol Implementation
    var supportedModels: [String] {
        ["hybrid-fast", "hybrid-balanced", "hybrid-deep", "hybrid-creative"]
    }
    
    var providerName: String { "Hybrid Multi-Agent" }
    
    func sendMessage(_ message: String, model: String?) async throws -> String {
        let complexity = analyzeComplexity(message)
        let selectedModel = model ?? "hybrid-balanced"
        
        // Controlla cache prima
        if let cached = responseCache.get(message, model: selectedModel) {
            return cached
        }
        
        let response: String
        
        switch selectedModel {
        case "hybrid-fast":
            response = try await coreAgents.processLocally(message, mode: .fast)
        case "hybrid-deep":
            response = try await remoteService.processRemotely(message, complexity: complexity, mode: .deep)
        case "hybrid-creative":
            response = try await remoteService.processRemotely(message, complexity: complexity, mode: .creative)
        default: // hybrid-balanced
            if complexity.isSimple {
                response = try await coreAgents.processLocally(message, mode: .balanced)
            } else {
                response = try await remoteService.processRemotely(message, complexity: complexity, mode: .balanced)
            }
        }
        
        // Salva in cache
        responseCache.set(message, response: response, model: selectedModel)
        return response
    }
    
    func validateConfiguration() async throws -> Bool {
        // Il servizio ibrido è sempre disponibile (core locale + fallback)
        return true
    }
    
    // MARK: - Private Methods
    private func analyzeComplexity(_ message: String) -> MessageComplexity {
        let wordCount = message.split(separator: " ").count
        let hasCodeKeywords = containsCodeKeywords(message)
        let hasComplexConcepts = containsComplexConcepts(message)
        let hasMultipleQuestions = message.components(separatedBy: "?").count > 2
        
        var complexityScore = 0
        
        // Analisi lunghezza
        if wordCount > 100 { complexityScore += 3 }
        else if wordCount > 50 { complexityScore += 2 }
        else if wordCount > 20 { complexityScore += 1 }
        
        // Analisi contenuto
        if hasCodeKeywords { complexityScore += 2 }
        if hasComplexConcepts { complexityScore += 2 }
        if hasMultipleQuestions { complexityScore += 1 }
        
        switch complexityScore {
        case 0...2:
            return .simple
        case 3...5:
            return .medium
        default:
            return .complex
        }
    }
    
    private func containsCodeKeywords(_ message: String) -> Bool {
        let codeKeywords = [
            "function", "class", "struct", "enum", "protocol", "var", "let",
            "import", "export", "return", "if", "else", "for", "while",
            "algorithm", "database", "API", "JSON", "XML", "SQL",
            "codice", "funzione", "classe", "algoritmo", "programmazione"
        ]
        
        let lowercased = message.lowercased()
        return codeKeywords.contains { lowercased.contains($0) }
    }
    
    private func containsComplexConcepts(_ message: String) -> Bool {
        let complexKeywords = [
            "architettura", "architecture", "design pattern", "scalabilità",
            "performance", "ottimizzazione", "sicurezza", "machine learning",
            "artificial intelligence", "blockchain", "microservizi", "cloud",
            "analizza", "confronta", "valuta", "strategia", "implementazione"
        ]
        
        let lowercased = message.lowercased()
        return complexKeywords.contains { lowercased.contains($0) }
    }
}

// MARK: - MessageComplexity
enum MessageComplexity {
    case simple, medium, complex
    
    var isSimple: Bool {
        return self == .simple
    }
    
    var description: String {
        switch self {
        case .simple:
            return "Semplice"
        case .medium:
            return "Media"
        case .complex:
            return "Complessa"
        }
    }
}

// MARK: - ProcessingMode
enum ProcessingMode {
    case fast, balanced, deep, creative
    
    var description: String {
        switch self {
        case .fast:
            return "Veloce"
        case .balanced:
            return "Bilanciato"
        case .deep:
            return "Approfondito"
        case .creative:
            return "Creativo"
        }
    }
}

// MARK: - CoreAgentSystem
class CoreAgentSystem {
    private let quickResponse = QuickResponseAgent()
    private let basicConversation = BasicConversationAgent()
    private let simpleAnalysis = SimpleAnalysisAgent()
    private let patternMatcher = PatternMatchingAgent()
    
    func processLocally(_ message: String, mode: ProcessingMode) async throws -> String {
        // Routing locale basato su pattern e modalità
        if isQuickResponse(message) {
            return try await quickResponse.process(message, mode: mode)
        } else if isAnalysisRequest(message) {
            return try await simpleAnalysis.process(message, mode: mode)
        } else if isPatternMatchingRequest(message) {
            return try await patternMatcher.process(message, mode: mode)
        } else {
            return try await basicConversation.process(message, mode: mode)
        }
    }
    
    private func isQuickResponse(_ message: String) -> Bool {
        let quickPatterns = [
            "ciao", "hello", "hi", "grazie", "thanks", "ok", "sì", "no",
            "bene", "good", "perfetto", "perfect", "d'accordo", "agree"
        ]
        let lowercased = message.lowercased()
        return quickPatterns.contains { lowercased.contains($0) } && message.count < 50
    }
    
    private func isAnalysisRequest(_ message: String) -> Bool {
        let analysisPatterns = [
            "analizza", "analyze", "confronta", "compare", "riassumi", "summarize",
            "spiega", "explain", "descrivi", "describe", "elenca", "list"
        ]
        let lowercased = message.lowercased()
        return analysisPatterns.contains { lowercased.contains($0) }
    }
    
    private func isPatternMatchingRequest(_ message: String) -> Bool {
        let patternKeywords = [
            "pattern", "template", "esempio", "example", "formato", "format",
            "struttura", "structure", "schema", "modello", "model"
        ]
        let lowercased = message.lowercased()
        return patternKeywords.contains { lowercased.contains($0) }
    }
}

// MARK: - Local Agents
class QuickResponseAgent {
    func process(_ message: String, mode: ProcessingMode) async throws -> String {
        // Simulazione tempo di elaborazione locale
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 secondi
        
        let responses = getQuickResponses()
        let lowercased = message.lowercased()
        
        for (pattern, response) in responses {
            if lowercased.contains(pattern) {
                return mode == .creative ? "🎨 " + response : response
            }
        }
        
        return mode == .fast ? "Ricevuto!" : "Ho ricevuto il tuo messaggio. Come posso aiutarti?"
    }
    
    private func getQuickResponses() -> [String: String] {
        return [
            "ciao": "Ciao! Come posso aiutarti oggi?",
            "hello": "Hello! How can I help you?",
            "hi": "Hi there! What can I do for you?",
            "grazie": "Prego! È stato un piacere aiutarti.",
            "thanks": "You're welcome! Happy to help.",
            "ok": "Perfetto! Procediamo.",
            "bene": "Ottimo! Continuiamo.",
            "d'accordo": "Perfetto, siamo allineati!"
        ]
    }
}

class BasicConversationAgent {
    func process(_ message: String, mode: ProcessingMode) async throws -> String {
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 secondi
        
        let wordCount = message.split(separator: " ").count
        
        switch mode {
        case .fast:
            return "Messaggio ricevuto (\(wordCount) parole). Elaborando..."
        case .balanced:
            return "Ho ricevuto il tuo messaggio di \(wordCount) parole. Sto elaborando una risposta appropriata basandomi sul contesto fornito."
        case .deep:
            return "Analizzando il tuo messaggio di \(wordCount) parole. Considerando multiple prospettive per fornirti una risposta completa e accurata."
        case .creative:
            return "🤔 Interessante! Il tuo messaggio di \(wordCount) parole mi ispira diverse riflessioni. Lasciami elaborare una risposta creativa..."
        }
    }
}

class SimpleAnalysisAgent {
    func process(_ message: String, mode: ProcessingMode) async throws -> String {
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 secondi
        
        let analysis = performBasicAnalysis(message)
        
        switch mode {
        case .fast:
            return "📊 Analisi rapida: \(analysis.summary)"
        case .balanced:
            return analysis.detailed
        case .deep:
            return analysis.comprehensive
        case .creative:
            return "🎯 " + analysis.creative
        }
    }
    
    private func performBasicAnalysis(_ message: String) -> AnalysisResult {
        let wordCount = message.split(separator: " ").count
        let charCount = message.count
        let sentenceCount = message.components(separatedBy: CharacterSet(charactersIn: ".!?")).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }.count
        let hasQuestions = message.contains("?")
        let hasExclamations = message.contains("!")
        
        let summary = "\(wordCount) parole, \(sentenceCount) frasi"
        
        let detailed = """
        📊 Analisi del messaggio:
        • Parole: \(wordCount)
        • Caratteri: \(charCount)
        • Frasi: \(sentenceCount)
        • Contiene domande: \(hasQuestions ? "Sì" : "No")
        • Tono: \(hasExclamations ? "Enfatico" : "Neutrale")
        """
        
        let comprehensive = """
        📊 Analisi completa del messaggio:
        
        **Struttura:**
        • Lunghezza: \(wordCount) parole, \(charCount) caratteri
        • Complessità: \(sentenceCount) frasi (\(wordCount/max(sentenceCount, 1)) parole/frase in media)
        
        **Contenuto:**
        • Tipo: \(hasQuestions ? "Interrogativo" : "Dichiarativo")
        • Tono: \(hasExclamations ? "Enfatico/Emotivo" : "Neutrale/Informativo")
        • Categoria: \(wordCount > 50 ? "Messaggio lungo" : "Messaggio breve")
        
        **Raccomandazioni:**
        • Risposta suggerita: \(hasQuestions ? "Dettagliata e informativa" : "Conferma e approfondimento")
        """
        
        let creative = """
        Questo messaggio di \(wordCount) parole danza tra \(sentenceCount) frasi come note in una sinfonia di comunicazione! 
        \(hasQuestions ? "🤔 Le domande che poni aprono porte verso nuove scoperte." : "💭 Le tue affermazioni costruiscono ponti di comprensione.")
        \(hasExclamations ? "⚡ L'energia che trasmetti è contagiosa!" : "🌊 Il tuo tono calmo invita alla riflessione.")
        """
        
        return AnalysisResult(
            summary: summary,
            detailed: detailed,
            comprehensive: comprehensive,
            creative: creative
        )
    }
}

class PatternMatchingAgent {
    func process(_ message: String, mode: ProcessingMode) async throws -> String {
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 secondi
        
        let patterns = identifyPatterns(message)
        
        switch mode {
        case .fast:
            return "Pattern identificati: \(patterns.count)"
        case .balanced:
            return "🔍 Pattern rilevati: \(patterns.joined(separator: ", "))"
        case .deep:
            return generateDeepPatternAnalysis(patterns)
        case .creative:
            return "🎨 I pattern nel tuo messaggio creano un mosaico di significati: \(patterns.joined(separator: " ✨ "))"
        }
    }
    
    private func identifyPatterns(_ message: String) -> [String] {
        var patterns: [String] = []
        let lowercased = message.lowercased()
        
        if lowercased.contains("come") || lowercased.contains("how") {
            patterns.append("Richiesta di istruzioni")
        }
        if lowercased.contains("perché") || lowercased.contains("why") {
            patterns.append("Richiesta di spiegazione")
        }
        if lowercased.contains("quando") || lowercased.contains("when") {
            patterns.append("Richiesta temporale")
        }
        if lowercased.contains("dove") || lowercased.contains("where") {
            patterns.append("Richiesta di localizzazione")
        }
        if message.contains("?") {
            patterns.append("Formato interrogativo")
        }
        if message.contains("!") {
            patterns.append("Tono enfatico")
        }
        
        return patterns.isEmpty ? ["Pattern conversazionale standard"] : patterns
    }
    
    private func generateDeepPatternAnalysis(_ patterns: [String]) -> String {
        return """
        🔍 Analisi pattern approfondita:
        
        Pattern identificati: \(patterns.count)
        \(patterns.enumerated().map { "\($0.offset + 1). \($0.element)" }.joined(separator: "\n"))
        
        Questa combinazione di pattern suggerisce un approccio di risposta che dovrebbe essere:
        \(patterns.contains("Richiesta di istruzioni") ? "• Strutturato e step-by-step\n" : "")
        \(patterns.contains("Richiesta di spiegazione") ? "• Esplicativo e dettagliato\n" : "")
        \(patterns.contains("Tono enfatico") ? "• Energico e coinvolgente\n" : "")
        \(patterns.contains("Formato interrogativo") ? "• Diretto e informativo\n" : "")
        """
    }
}

// MARK: - Supporting Types
struct AnalysisResult {
    let summary: String
    let detailed: String
    let comprehensive: String
    let creative: String
}

// MARK: - RemoteAgentService (Mock Implementation)
class RemoteAgentService {
    func processRemotely(_ message: String, complexity: MessageComplexity, mode: ProcessingMode) async throws -> String {
        // Simulazione chiamata remota
        let delay = UInt64(complexity == .complex ? 3_000_000_000 : 2_000_000_000)
        try await Task.sleep(nanoseconds: delay)
        
        return """
        🌐 [Elaborazione Remota - \(mode.description)]
        
        Messaggio analizzato con complessità \(complexity.description.lowercased()).
        
        Questa è una risposta simulata che dimostra l'integrazione tra:
        • Sistema locale per analisi rapida
        • Servizi remoti per elaborazione avanzata
        • Cache intelligente per ottimizzazione
        
        In produzione, questo si collegherebbe ai servizi AI reali per fornire risposte sofisticate basate sulla complessità rilevata.
        """
    }
}

// MARK: - ResponseCache
class ResponseCache {
    private var cache: [String: CacheEntry] = [:]
    private let maxCacheSize = 100
    private let cacheExpirationTime: TimeInterval = 3600 // 1 ora
    
    func get(_ message: String, model: String) -> String? {
        let key = generateKey(message: message, model: model)
        
        guard let entry = cache[key],
              Date().timeIntervalSince(entry.timestamp) < cacheExpirationTime else {
            cache.removeValue(forKey: key)
            return nil
        }
        
        return entry.response
    }
    
    func set(_ message: String, response: String, model: String) {
        let key = generateKey(message: message, model: model)
        
        // Rimuovi entry più vecchie se necessario
        if cache.count >= maxCacheSize {
            let oldestKey = cache.min { $0.value.timestamp < $1.value.timestamp }?.key
            if let oldestKey = oldestKey {
                cache.removeValue(forKey: oldestKey)
            }
        }
        
        cache[key] = CacheEntry(response: response, timestamp: Date())
    }
    
    private func generateKey(message: String, model: String) -> String {
        return "\(model)_\(message.hashValue)"
    }
    
    private struct CacheEntry {
        let response: String
        let timestamp: Date
    }
}