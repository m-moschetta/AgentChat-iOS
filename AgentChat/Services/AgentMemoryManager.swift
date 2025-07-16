//
//  AgentMemoryManager.swift
//  AgentChat
//
//  Created by Mario Moschetta on 04/07/25.
//

import Foundation
import SwiftUI
import Combine

// MARK: - Memory Entry Model
struct MemoryEntry: Codable, Identifiable {
    let id: UUID
    let agentId: UUID
    let chatId: UUID
    let content: String
    let type: MemoryType
    let importance: ImportanceLevel
    let timestamp: Date
    let expiresAt: Date?
    let metadata: [String: String]
    
    init(
        agentId: UUID,
        chatId: UUID,
        content: String,
        type: MemoryType,
        importance: ImportanceLevel = .medium,
        expiresAt: Date? = nil,
        metadata: [String: String] = [:]
    ) {
        self.id = UUID()
        self.agentId = agentId
        self.chatId = chatId
        self.content = content
        self.type = type
        self.importance = importance
        self.timestamp = Date()
        self.expiresAt = expiresAt
        self.metadata = metadata
    }
}

enum MemoryType: String, Codable, CaseIterable {
    case userPreference = "user_preference"
    case conversationContext = "conversation_context"
    case factualInformation = "factual_information"
    case personalDetail = "personal_detail"
    case taskHistory = "task_history"
    case errorPattern = "error_pattern"
    case successPattern = "success_pattern"
    
    var displayName: String {
        switch self {
        case .userPreference: return "Preferenza Utente"
        case .conversationContext: return "Contesto Conversazione"
        case .factualInformation: return "Informazione Fattuale"
        case .personalDetail: return "Dettaglio Personale"
        case .taskHistory: return "Cronologia Attività"
        case .errorPattern: return "Pattern Errore"
        case .successPattern: return "Pattern Successo"
        }
    }
}

enum ImportanceLevel: Int, Codable, CaseIterable {
    case low = 1
    case medium = 2
    case high = 3
    case critical = 4
    
    var displayName: String {
        switch self {
        case .low: return "Bassa"
        case .medium: return "Media"
        case .high: return "Alta"
        case .critical: return "Critica"
        }
    }
    
    var color: Color {
        switch self {
        case .low: return .gray
        case .medium: return .blue
        case .high: return .orange
        case .critical: return .red
        }
    }
}

// MARK: - Memory Context
struct MemoryContext {
    let entries: [MemoryEntry]
    let summary: String
    let relevanceScore: Double
    let lastUpdated: Date
    
    var contextPrompt: String {
        guard !entries.isEmpty else { return "" }
        
        let sortedEntries = entries.sorted { $0.importance.rawValue > $1.importance.rawValue }
        let contextLines = sortedEntries.prefix(10).map { entry in
            "[\(entry.type.displayName)] \(entry.content)"
        }
        
        return """
        Contesto dalla memoria dell'agente:
        \(contextLines.joined(separator: "\n"))
        
        Riepilogo: \(summary)
        """
    }
}

// MARK: - Agent Memory Manager
class AgentMemoryManager: ObservableObject {
    static let shared = AgentMemoryManager()
    
    @Published private var memories: [UUID: [MemoryEntry]] = [:]
    private let userDefaults = UserDefaults.standard
    private let memoriesKey = "agent_memories"
    private let maxMemoriesPerAgent = 1000
    private let maxContextEntries = 20
    private let memoryQueue = DispatchQueue(label: "com.agentchat.memory", qos: .utility)
    
    private init() {
        loadMemories()
        startCleanupTimer()
    }
    
    // MARK: - Public Methods
    
    /// Salva una nuova memoria per un agente
    func saveMemory(
        for agentId: UUID,
        chatId: UUID,
        content: String,
        type: MemoryType,
        importance: ImportanceLevel = .medium,
        expiresAt: Date? = nil,
        metadata: [String: String] = [:]
    ) {
        let entry = MemoryEntry(
            agentId: agentId,
            chatId: chatId,
            content: content,
            type: type,
            importance: importance,
            expiresAt: expiresAt,
            metadata: metadata
        )
        
        memoryQueue.async { [weak self] in
            guard let self = self else { return }
            
            if self.memories[agentId] == nil {
                self.memories[agentId] = []
            }
            
            self.memories[agentId]?.append(entry)
            
            // Mantieni solo le memorie più recenti e importanti
            self.cleanupMemoriesForAgent(agentId)
            
            DispatchQueue.main.async {
                self.saveMemories()
            }
        }
    }
    
    /// Recupera il contesto di memoria per un agente
    func getMemoryContext(for agentId: UUID, chatId: UUID? = nil) -> MemoryContext {
        return memoryQueue.sync {
            guard let agentMemories = memories[agentId] else {
                return MemoryContext(entries: [], summary: "", relevanceScore: 0.0, lastUpdated: Date())
            }
            
            // Filtra per chat specifica se richiesto
            let relevantMemories: [MemoryEntry]
            if let chatId = chatId {
                relevantMemories = agentMemories.filter { $0.chatId == chatId || $0.type == .userPreference || $0.type == .personalDetail }
            } else {
                relevantMemories = agentMemories
            }
            
            // Ordina per importanza e data
            let sortedMemories = relevantMemories
                .filter { !isExpired($0) }
                .sorted { entry1, entry2 in
                    if entry1.importance.rawValue != entry2.importance.rawValue {
                        return entry1.importance.rawValue > entry2.importance.rawValue
                    }
                    return entry1.timestamp > entry2.timestamp
                }
                .prefix(maxContextEntries)
            
            let summary = generateSummary(from: Array(sortedMemories))
            let relevanceScore = calculateRelevanceScore(Array(sortedMemories))
            
            return MemoryContext(
                entries: Array(sortedMemories),
                summary: summary,
                relevanceScore: relevanceScore,
                lastUpdated: Date()
            )
        }
    }
    
    /// Analizza un messaggio e estrae informazioni da memorizzare
    func analyzeAndStoreMessage(
        _ message: Message,
        for agentId: UUID,
        chatId: UUID
    ) {
        let content = message.content.lowercased()
        
        // Analizza preferenze utente
        analyzeUserPreferences(content, agentId: agentId, chatId: chatId)
        
        // Analizza informazioni personali
        analyzePersonalDetails(content, agentId: agentId, chatId: chatId)
        
        // Analizza pattern di successo/errore
        analyzePatterns(message, agentId: agentId, chatId: chatId)
        
        // Salva contesto conversazione se importante
        if message.content.count > 50 {
            saveMemory(
                for: agentId,
                chatId: chatId,
                content: message.content,
                type: .conversationContext,
                importance: .medium,
                expiresAt: Calendar.current.date(byAdding: .day, value: 30, to: Date())
            )
        }
    }
    
    /// Elimina tutte le memorie di un agente
    func clearMemories(for agentId: UUID) {
        memories[agentId] = nil
        saveMemories()
    }
    
    /// Elimina le memorie di una chat specifica
    func clearChatMemories(for agentId: UUID, chatId: UUID) {
        memories[agentId]?.removeAll { $0.chatId == chatId }
        saveMemories()
    }
    
    /// Ottieni statistiche memoria per un agente
    func getMemoryStatistics(for agentId: UUID) -> (total: Int, byType: [MemoryType: Int], byImportance: [ImportanceLevel: Int]) {
        guard let agentMemories = memories[agentId] else {
            return (0, [:], [:])
        }
        
        let activeMemories = agentMemories.filter { !isExpired($0) }
        
        var byType: [MemoryType: Int] = [:]
        var byImportance: [ImportanceLevel: Int] = [:]
        
        for memory in activeMemories {
            byType[memory.type, default: 0] += 1
            byImportance[memory.importance, default: 0] += 1
        }
        
        return (activeMemories.count, byType, byImportance)
    }
    
    /// Esporta le memorie di un agente
    func exportMemories(for agentId: UUID) -> Data? {
        guard let agentMemories = memories[agentId] else { return nil }
        
        do {
            return try JSONEncoder().encode(agentMemories)
        } catch {
            print("Errore nell'esportazione delle memorie: \(error)")
            return nil
        }
    }
    
    /// Importa memorie per un agente
    func importMemories(for agentId: UUID, from data: Data) -> Bool {
        do {
            let importedMemories = try JSONDecoder().decode([MemoryEntry].self, from: data)
            
            if memories[agentId] == nil {
                memories[agentId] = []
            }
            
            memories[agentId]?.append(contentsOf: importedMemories)
            cleanupMemoriesForAgent(agentId)
            saveMemories()
            
            return true
        } catch {
            print("Errore nell'importazione delle memorie: \(error)")
            return false
        }
    }
    
    // MARK: - Private Methods
    
    private func analyzeUserPreferences(_ content: String, agentId: UUID, chatId: UUID) {
        let preferenceKeywords = [
            ("preferisco", "Preferenza espressa"),
            ("mi piace", "Gradimento"),
            ("non mi piace", "Avversione"),
            ("odio", "Forte avversione"),
            ("amo", "Forte gradimento"),
            ("sempre", "Comportamento abituale"),
            ("mai", "Comportamento evitato")
        ]
        
        for (keyword, description) in preferenceKeywords {
            if content.contains(keyword) {
                saveMemory(
                    for: agentId,
                    chatId: chatId,
                    content: "\(description): \(content)",
                    type: .userPreference,
                    importance: .high,
                    metadata: ["keyword": keyword]
                )
                break
            }
        }
    }
    
    private func analyzePersonalDetails(_ content: String, agentId: UUID, chatId: UUID) {
        let personalKeywords = [
            "mi chiamo", "sono", "lavoro", "studio", "vivo", "nato", "famiglia",
            "sposato", "fidanzato", "single", "figli", "anni", "età"
        ]
        
        for keyword in personalKeywords {
            if content.contains(keyword) {
                saveMemory(
                    for: agentId,
                    chatId: chatId,
                    content: content,
                    type: .personalDetail,
                    importance: .critical,
                    metadata: ["keyword": keyword]
                )
                break
            }
        }
    }
    
    private func analyzePatterns(_ message: Message, agentId: UUID, chatId: UUID) {
        let content = message.content.lowercased()
        
        // Pattern di successo
        let successKeywords = ["grazie", "perfetto", "ottimo", "bravo", "giusto", "corretto"]
        if successKeywords.contains(where: content.contains) {
            saveMemory(
                for: agentId,
                chatId: chatId,
                content: "Risposta apprezzata: \(message.content)",
                type: .successPattern,
                importance: .medium
            )
        }
        
        // Pattern di errore
        let errorKeywords = ["sbagliato", "errore", "non funziona", "problema", "non va"]
        if errorKeywords.contains(where: content.contains) {
            saveMemory(
                for: agentId,
                chatId: chatId,
                content: "Problema identificato: \(message.content)",
                type: .errorPattern,
                importance: .high
            )
        }
    }
    
    private func generateSummary(from memories: [MemoryEntry]) -> String {
        guard !memories.isEmpty else { return "Nessuna memoria disponibile" }
        
        let typeGroups = Dictionary(grouping: memories) { $0.type }
        var summaryParts: [String] = []
        
        for (type, entries) in typeGroups {
            summaryParts.append("\(type.displayName): \(entries.count) voci")
        }
        
        return summaryParts.joined(separator: ", ")
    }
    
    private func calculateRelevanceScore(_ memories: [MemoryEntry]) -> Double {
        guard !memories.isEmpty else { return 0.0 }
        
        let totalImportance = memories.reduce(0) { $0 + $1.importance.rawValue }
        let maxPossibleImportance = memories.count * ImportanceLevel.critical.rawValue
        
        return Double(totalImportance) / Double(maxPossibleImportance)
    }
    
    private func isExpired(_ memory: MemoryEntry) -> Bool {
        guard let expiresAt = memory.expiresAt else { return false }
        return Date() > expiresAt
    }
    
    private func cleanupMemoriesForAgent(_ agentId: UUID) {
        guard var agentMemories = memories[agentId] else { return }
        
        // Rimuovi memorie scadute
        agentMemories.removeAll { isExpired($0) }
        
        // Se ci sono troppe memorie, mantieni solo le più importanti e recenti
        if agentMemories.count > maxMemoriesPerAgent {
            agentMemories.sort { memory1, memory2 in
                if memory1.importance.rawValue != memory2.importance.rawValue {
                    return memory1.importance.rawValue > memory2.importance.rawValue
                }
                return memory1.timestamp > memory2.timestamp
            }
            
            agentMemories = Array(agentMemories.prefix(maxMemoriesPerAgent))
        }
        
        memories[agentId] = agentMemories
    }
    
    private func startCleanupTimer() {
        Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { _ in
            self.performCleanup()
        }
    }
    
    private func performCleanup() {
        for agentId in memories.keys {
            cleanupMemoriesForAgent(agentId)
        }
        saveMemories()
    }
    
    private func loadMemories() {
        guard let data = userDefaults.data(forKey: memoriesKey) else { return }
        
        do {
            let decodedMemories = try JSONDecoder().decode([UUID: [MemoryEntry]].self, from: data)
            memories = decodedMemories
        } catch {
            print("Errore nel caricamento delle memorie: \(error)")
        }
    }
    
    private func saveMemories() {
        do {
            let data = try JSONEncoder().encode(memories)
            userDefaults.set(data, forKey: memoriesKey)
        } catch {
            print("Errore nel salvataggio delle memorie: \(error)")
        }
    }
}

// MARK: - Memory Extensions
extension AgentMemoryManager {
    /// Cerca nelle memorie di un agente
    func searchMemories(for agentId: UUID, query: String) -> [MemoryEntry] {
        guard let agentMemories = memories[agentId] else { return [] }
        
        let lowercaseQuery = query.lowercased()
        return agentMemories.filter { memory in
            !isExpired(memory) &&
            memory.content.lowercased().contains(lowercaseQuery)
        }.sorted { $0.importance.rawValue > $1.importance.rawValue }
    }
    
    /// Ottieni memorie per tipo
    func getMemories(for agentId: UUID, type: MemoryType) -> [MemoryEntry] {
        guard let agentMemories = memories[agentId] else { return [] }
        
        return agentMemories
            .filter { $0.type == type && !isExpired($0) }
            .sorted { $0.timestamp > $1.timestamp }
    }
    
    /// Aggiorna l'importanza di una memoria
    func updateMemoryImportance(_ memoryId: UUID, newImportance: ImportanceLevel) {
        for agentId in memories.keys {
            if let index = memories[agentId]?.firstIndex(where: { $0.id == memoryId }) {
                var updatedMemory = memories[agentId]![index]
                let newMemory = MemoryEntry(
                    agentId: updatedMemory.agentId,
                    chatId: updatedMemory.chatId,
                    content: updatedMemory.content,
                    type: updatedMemory.type,
                    importance: newImportance,
                    metadata: updatedMemory.metadata
                )
                memories[agentId]![index] = newMemory
                saveMemories()
                break
            }
        }
    }
}