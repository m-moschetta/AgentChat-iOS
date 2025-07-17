//
//  Chat.swift
//  AgentChat
//
//  Created by Mario Moschetta on 04/07/25.
//

import Foundation
import Combine

// MARK: - Chat Type
enum ChatType: String, Codable, CaseIterable {
    case single = "single"
    case group = "group"
    
    var displayName: String {
        switch self {
        case .single: return "Chat Singola"
        case .group: return "Chat di Gruppo"
        }
    }
}

// MARK: - Chat
class Chat: Identifiable, Hashable, Codable {
    let id: UUID
    var messages: [Message]
    let agentType: AgentType
    let provider: AssistantProvider?
    var selectedModel: String?
    let n8nWorkflow: N8NWorkflow?
    var agentConfiguration: AgentConfiguration?
    var chatType: ChatType
    var title: String
    var isMemoryEnabled: Bool
    let createdAt: Date
    var lastActivity: Date
    var groupTemplate: AgentGroupTemplate?
    private let memoryManager: AgentMemoryManager

    // Inizializzatore designato
    init(id: UUID = UUID(),
         messages: [Message] = [],
         agentType: AgentType,
         provider: AssistantProvider? = nil,
         selectedModel: String? = nil,
         n8nWorkflow: N8NWorkflow? = nil,
         agentConfiguration: AgentConfiguration? = nil,
         chatType: ChatType = .single,
         title: String? = nil,
         isMemoryEnabled: Bool = true,
         createdAt: Date = Date(),
         lastActivity: Date = Date(),
         groupTemplate: AgentGroupTemplate? = nil,
         memoryManager: AgentMemoryManager) {
        self.id = id
        self.messages = messages
        self.agentType = agentType
        self.provider = provider
        self.selectedModel = selectedModel
        self.n8nWorkflow = n8nWorkflow
        self.agentConfiguration = agentConfiguration
        self.chatType = chatType
        self.title = title ?? agentConfiguration?.name ?? agentType.displayName
        self.isMemoryEnabled = isMemoryEnabled
        self.createdAt = createdAt
        self.lastActivity = lastActivity
        self.groupTemplate = groupTemplate
        self.memoryManager = memoryManager
    }
    
    // Inizializzatore da ChatEntity
    init(fromEntity entity: ChatEntity, memoryManager: AgentMemoryManager) {
        let decoder = JSONDecoder()

        self.id = entity.id ?? UUID()
        self.agentType = AgentType(rawValue: entity.agentTypeString ?? "") ?? .openAI
        self.chatType = ChatType(rawValue: entity.chatTypeString ?? "") ?? .single
        self.title = entity.title ?? ""
        self.isMemoryEnabled = entity.isMemoryEnabled
        self.createdAt = entity.createdAt ?? Date()
        self.lastActivity = entity.lastActivity ?? Date()
        self.selectedModel = entity.selectedModel

        self.messages = (entity.messages as? Set<MessageEntity> ?? []).map { Message.fromEntityUnsafe($0) }.sorted(by: { $0.timestamp < $1.timestamp })

        if let jsonString = entity.providerJSON, let data = jsonString.data(using: .utf8) {
            self.provider = try? decoder.decode(AssistantProvider.self, from: data)
        } else {
            self.provider = nil
        }

        if let jsonString = entity.n8nWorkflowJSON, let data = jsonString.data(using: .utf8) {
            self.n8nWorkflow = try? decoder.decode(N8NWorkflow.self, from: data)
        } else {
            self.n8nWorkflow = nil
        }

        if let jsonString = entity.agentConfigurationJSON, let data = jsonString.data(using: .utf8) {
            self.agentConfiguration = try? decoder.decode(AgentConfiguration.self, from: data)
        } else {
            self.agentConfiguration = nil
        }

        if let jsonString = entity.groupTemplateJSON, let data = jsonString.data(using: .utf8) {
            self.groupTemplate = try? decoder.decode(AgentGroupTemplate.self, from: data)
        } else {
            self.groupTemplate = nil
        }
        self.memoryManager = memoryManager
    }
    
    var lastMessage: Message? {
        return messages.last
    }
    
    var displayTitle: String {
        if title.isEmpty {
            return agentConfiguration?.name ?? agentType.displayName
        }
        return title
    }
    
    var agentIcon: String {
        return agentConfiguration?.icon ?? agentType.icon
    }
    
    var systemPrompt: String {
        return agentConfiguration?.systemPrompt ?? ""
    }
    
    // Aggiorna l'ultima attività
    func updateLastActivity() {
        lastActivity = Date()
    }
    
    // Aggiungi un messaggio e aggiorna l'attività
    func addMessage(_ message: Message) {
        messages.append(message)
        updateLastActivity()
        
        // Analizza e salva nella memoria se abilitata
        if isMemoryEnabled, let agentConfig = agentConfiguration {
            memoryManager.analyzeAndStoreMessage(
                message,
                for: agentConfig.id,
                chatId: id
            )
        }
    }
    
    // Ottieni il contesto di memoria per questa chat
    func getMemoryContext() -> MemoryContext? {
        guard isMemoryEnabled, let agentConfig = agentConfiguration else { return nil }
        return memoryManager.getMemoryContext(for: agentConfig.id, chatId: id)
    }
    
    // Costruisci il prompt completo con memoria
    func buildContextualPrompt(for userMessage: String) -> String {
        var prompt = ""
        
        // Aggiungi system prompt dell'agente
        if let systemPrompt = agentConfiguration?.systemPrompt, !systemPrompt.isEmpty {
            prompt += "System: \(systemPrompt)\n\n"
        }
        
        // Aggiungi contesto di memoria se disponibile
        if let memoryContext = getMemoryContext(), !memoryContext.entries.isEmpty {
            prompt += "\(memoryContext.contextPrompt)\n\n"
        }
        
        // Aggiungi messaggio utente
        prompt += "User: \(userMessage)"
        
        return prompt
    }
    
    // MARK: - Hashable
    static func == (lhs: Chat, rhs: Chat) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // MARK: - Codable Implementation
    private enum CodingKeys: String, CodingKey {
        case id, messages, agentType, provider, selectedModel
        case n8nWorkflow, agentConfiguration, chatType, title
        case isMemoryEnabled, createdAt, lastActivity, groupTemplate
        // memoryManager is excluded from encoding/decoding
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        messages = try container.decode([Message].self, forKey: .messages)
        agentType = try container.decode(AgentType.self, forKey: .agentType)
        provider = try container.decodeIfPresent(AssistantProvider.self, forKey: .provider)
        selectedModel = try container.decodeIfPresent(String.self, forKey: .selectedModel)
        n8nWorkflow = try container.decodeIfPresent(N8NWorkflow.self, forKey: .n8nWorkflow)
        agentConfiguration = try container.decodeIfPresent(AgentConfiguration.self, forKey: .agentConfiguration)
        chatType = try container.decode(ChatType.self, forKey: .chatType)
        title = try container.decode(String.self, forKey: .title)
        isMemoryEnabled = try container.decode(Bool.self, forKey: .isMemoryEnabled)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        lastActivity = try container.decode(Date.self, forKey: .lastActivity)
        groupTemplate = try container.decodeIfPresent(AgentGroupTemplate.self, forKey: .groupTemplate)
        
        // Initialize memoryManager with shared instance
        memoryManager = AgentMemoryManager.shared
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(messages, forKey: .messages)
        try container.encode(agentType, forKey: .agentType)
        try container.encodeIfPresent(provider, forKey: .provider)
        try container.encodeIfPresent(selectedModel, forKey: .selectedModel)
        try container.encodeIfPresent(n8nWorkflow, forKey: .n8nWorkflow)
        try container.encodeIfPresent(agentConfiguration, forKey: .agentConfiguration)
        try container.encode(chatType, forKey: .chatType)
        try container.encode(title, forKey: .title)
        try container.encode(isMemoryEnabled, forKey: .isMemoryEnabled)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(lastActivity, forKey: .lastActivity)
        try container.encodeIfPresent(groupTemplate, forKey: .groupTemplate)
        // memoryManager is not encoded
    }
}