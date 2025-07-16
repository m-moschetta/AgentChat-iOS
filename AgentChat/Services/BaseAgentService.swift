//
//  BaseAgentService.swift
//  AgentChat
//
//  Created by Mario Moschetta on 04/07/25.
//

import Foundation
import Combine

// MARK: - Agent Service Protocol
protocol AgentServiceProtocol: ChatServiceProtocol {
    // Configurazione agente
    var agentConfiguration: AgentConfiguration? { get set }
    
    // Gestione memoria
    func saveConversationContext(_ context: ConversationContext) async throws
    func loadConversationContext(for chatId: UUID) async throws -> ConversationContext?
    func clearConversationMemory(for chatId: UUID) async throws
    
    // Capacità agente
    var capabilities: [AgentCapability] { get }
    var isMultiAgentCapable: Bool { get }
    
    // Collaborazione
    func canCollaborateWith(_ otherAgent: AgentServiceProtocol) -> Bool
    func processCollaborativeMessage(_ message: CollaborativeMessage) async throws -> String
}

// MARK: - Agent Capabilities
enum AgentCapability: String, CaseIterable, Codable {
    case textGeneration = "text_generation"
    case codeGeneration = "code_generation"
    case dataAnalysis = "data_analysis"
    case webSearch = "web_search"
    case imageGeneration = "image_generation"
    case workflowAutomation = "workflow_automation"
    case memoryRetention = "memory_retention"
    case multiModalInput = "multimodal_input"
    case realTimeData = "realtime_data"
    case collaboration = "collaboration"
}

// MARK: - Conversation Context
struct ConversationContext: Codable {
    let chatId: UUID
    let agentId: UUID
    var messages: [ContextMessage]
    var summary: String?
    var lastUpdated: Date
    var metadata: [String: String]
    
    init(chatId: UUID, agentId: UUID) {
        self.chatId = chatId
        self.agentId = agentId
        self.messages = []
        self.lastUpdated = Date()
        self.metadata = [:]
    }
}

struct ContextMessage: Codable {
    let id: UUID
    let role: String
    let content: String
    let timestamp: Date
    let metadata: [String: String]
    
    init(role: String, content: String, metadata: [String: String] = [:]) {
        self.id = UUID()
        self.role = role
        self.content = content
        self.timestamp = Date()
        self.metadata = metadata
    }
}

// MARK: - Collaborative Message
struct CollaborativeMessage {
    let id: UUID
    let content: String
    let fromAgent: UUID
    let toAgent: UUID?
    let taskContext: TaskContext?
    let priority: MessagePriority
    let timestamp: Date
    
    init(content: String, fromAgent: UUID, toAgent: UUID? = nil, taskContext: TaskContext? = nil, priority: MessagePriority = .normal) {
        self.id = UUID()
        self.content = content
        self.fromAgent = fromAgent
        self.toAgent = toAgent
        self.taskContext = taskContext
        self.priority = priority
        self.timestamp = Date()
    }
}

struct TaskContext: Codable {
    let taskId: UUID
    let taskType: TaskType
    let parameters: [String: String]
    let deadline: Date?
}

enum TaskType: String, Codable, CaseIterable {
    case research = "research"
    case analysis = "analysis"
    case generation = "generation"
    case review = "review"
    case automation = "automation"
    case collaboration = "collaboration"
}

enum MessagePriority: Int, CaseIterable {
    case low = 1
    case normal = 2
    case high = 3
    case urgent = 4
}

// MARK: - Base Agent Service Implementation
class BaseAgentService: AgentServiceProtocol {
    
    // MARK: - Properties
    var agentConfiguration: AgentConfiguration?
    private let memoryManager: AgentMemoryManager
    private let collaborationManager: AgentCollaborationManager
    
    // MARK: - Initialization
    init(configuration: AgentConfiguration? = nil) {
        self.agentConfiguration = configuration
        self.memoryManager = AgentMemoryManager.shared
        self.collaborationManager = AgentCollaborationManager.shared
    }
    
    // MARK: - ChatServiceProtocol Implementation
    var supportedModels: [String] {
        return ["base-agent-model"]
    }
    
    var providerName: String {
        return agentConfiguration?.name ?? "Base Agent"
    }
    
    func sendMessage(_ message: String, model: String?) async throws -> String {
        // Implementazione base - da sovrascrivere nelle sottoclassi
        throw AgentServiceError.notImplemented
    }
    
    func validateConfiguration() async throws {
        guard let config = agentConfiguration else {
            throw AgentServiceError.missingConfiguration
        }
        
        // Validazione base della configurazione
        guard !config.name.isEmpty else {
            throw AgentServiceError.invalidConfiguration("Agent name cannot be empty")
        }
        

    }
    
    // MARK: - AgentServiceProtocol Implementation
    var capabilities: [AgentCapability] {
        return [.textGeneration, .memoryRetention]
    }
    
    var isMultiAgentCapable: Bool {
        return capabilities.contains(.collaboration)
    }
    
    func saveConversationContext(_ context: ConversationContext) async throws {
        // Save conversation context using memory manager
        for message in context.messages {
            AgentMemoryManager.shared.saveMemory(
                for: context.agentId,
                chatId: context.chatId,
                content: message.content,
                type: .conversationContext
            )
        }
    }
    
    func loadConversationContext(for chatId: UUID) async throws -> ConversationContext? {
        guard let agentId = agentConfiguration?.id else {
            throw AgentServiceError.missingConfiguration
        }
        
        let memories = AgentMemoryManager.shared.getMemories(for: agentId, type: .conversationContext)
        let contextMessages = memories.compactMap { memory -> ContextMessage? in
            guard let role = memory.metadata["role"] else { return nil }
            return ContextMessage(role: role, content: memory.content, metadata: memory.metadata)
        }
        
        if contextMessages.isEmpty {
            return nil
        } else {
            var context = ConversationContext(chatId: chatId, agentId: agentId)
            context.messages = contextMessages
            return context
        }
    }
    
    func clearConversationMemory(for chatId: UUID) async throws {
        guard let agentId = agentConfiguration?.id else {
            throw AgentServiceError.missingConfiguration
        }
        AgentMemoryManager.shared.clearMemories(for: agentId)
    }
    
    func canCollaborateWith(_ otherAgent: AgentServiceProtocol) -> Bool {
        return isMultiAgentCapable && otherAgent.isMultiAgentCapable
    }
    
    func processCollaborativeMessage(_ message: CollaborativeMessage) async throws -> String {
        guard isMultiAgentCapable else {
            throw AgentServiceError.collaborationNotSupported
        }
        
        // Implementazione base - da sovrascrivere nelle sottoclassi
        return try await collaborationManager.processMessage(message, for: self)
    }
    
    // MARK: - Internal Methods
    func buildContextualPrompt(from message: String, context: ConversationContext?) -> String {
        guard let config = agentConfiguration else {
            return message
        }
        
        var prompt = ""
        
        // Aggiungi il system prompt
        if !config.systemPrompt.isEmpty {
            prompt += "System: \(config.systemPrompt)\n\n"
        }
        
        // Aggiungi personalità e ruolo
        if !config.personality.isEmpty {
            prompt += "Personality: \(config.personality)\n"
        }
        
        if !config.role.isEmpty {
            prompt += "Role: \(config.role)\n\n"
        }
        
        // Aggiungi contesto conversazione se disponibile
        if let context = context, !context.messages.isEmpty {
            prompt += "Previous conversation context:\n"
            let recentMessages = context.messages.suffix(config.contextWindow)
            for msg in recentMessages {
                prompt += "\(msg.role): \(msg.content)\n"
            }
            prompt += "\n"
        }
        
        // Aggiungi il messaggio corrente
        prompt += "User: \(message)"
        
        return prompt
    }
    
    func updateConversationContext(_ context: inout ConversationContext, userMessage: String, assistantResponse: String) {
        // Aggiungi messaggio utente
        context.messages.append(ContextMessage(role: "user", content: userMessage))
        
        // Aggiungi risposta assistente
        context.messages.append(ContextMessage(role: "assistant", content: assistantResponse))
        
        // Mantieni solo gli ultimi N messaggi secondo contextWindow
        if let config = agentConfiguration {
            let maxMessages = config.contextWindow * 2 // user + assistant per ogni scambio
            if context.messages.count > maxMessages {
                context.messages = Array(context.messages.suffix(maxMessages))
            }
        }
        
        context.lastUpdated = Date()
    }
}

// MARK: - Agent Service Errors
enum AgentServiceError: LocalizedError {
    case notImplemented
    case missingConfiguration
    case invalidConfiguration(String)
    case collaborationNotSupported
    case memoryError(String)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .notImplemented:
            return "Method not implemented in base class"
        case .missingConfiguration:
            return "Agent configuration is missing"
        case .invalidConfiguration(let message):
            return "Invalid configuration: \(message)"
        case .collaborationNotSupported:
            return "This agent does not support collaboration"
        case .memoryError(let message):
            return "Memory error: \(message)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Agent Memory Manager
// AgentMemoryManager è definito in AgentMemoryManager.swift

// MARK: - Agent Collaboration Manager
class AgentCollaborationManager {
    static let shared = AgentCollaborationManager()
    
    private var activeCollaborations: [UUID: CollaborationSession] = [:]
    
    private init() {}
    
    func processMessage(_ message: CollaborativeMessage, for agent: AgentServiceProtocol) async throws -> String {
        // Implementazione base per la gestione dei messaggi collaborativi
        // Questa sarà estesa nelle fasi successive del refactoring
        
        guard let taskContext = message.taskContext else {
            return "Received collaborative message: \(message.content)"
        }
        
        switch taskContext.taskType {
        case .research:
            return "Processing research task: \(message.content)"
        case .analysis:
            return "Processing analysis task: \(message.content)"
        case .generation:
            return "Processing generation task: \(message.content)"
        case .review:
            return "Processing review task: \(message.content)"
        case .automation:
            return "Processing automation task: \(message.content)"
        case .collaboration:
            return "Processing collaboration task: \(message.content)"
        }
    }
}

struct CollaborationSession {
    let id: UUID
    let participants: [UUID]
    let taskContext: TaskContext
    let startTime: Date
    var messages: [CollaborativeMessage]
    
    init(participants: [UUID], taskContext: TaskContext) {
        self.id = UUID()
        self.participants = participants
        self.taskContext = taskContext
        self.startTime = Date()
        self.messages = []
    }
}