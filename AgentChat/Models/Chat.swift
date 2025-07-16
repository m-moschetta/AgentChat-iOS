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
class Chat: Identifiable, ObservableObject, Hashable, Codable {
    let id: UUID
    @Published var messages: [Message] = []
    let agentType: AgentType
    let provider: AssistantProvider?
    @Published var selectedModel: String?
    let n8nWorkflow: N8NWorkflow?
    
    // Nuove proprietà per agenti configurabili
    @Published var agentConfiguration: AgentConfiguration?
    @Published var chatType: ChatType = .single
    @Published var title: String = ""
    @Published var isMemoryEnabled: Bool = true
    let createdAt: Date
    @Published var lastActivity: Date = Date()
    
    // Proprietà per chat di gruppo
    var groupTemplate: AgentGroupTemplate?
    
    // Inizializzatore originale (per compatibilità)
    init(id: UUID = UUID(), agentType: AgentType, messages: [Message] = [], provider: AssistantProvider? = nil, selectedModel: String? = nil, n8nWorkflow: N8NWorkflow? = nil) {
        self.id = id
        self.agentType = agentType
        self.provider = provider
        self.n8nWorkflow = n8nWorkflow
        self.messages = messages
        self.selectedModel = selectedModel
        
        // Valori di default per nuove proprietà
        self.agentConfiguration = nil
        self.chatType = .single
        self.title = agentType.displayName
        self.isMemoryEnabled = true
        self.createdAt = Date()
        self.lastActivity = Date()
        self.groupTemplate = nil
    }
    
    // Nuovo inizializzatore per agenti configurabili
    init(
        id: UUID = UUID(),
        agentConfiguration: AgentConfiguration,
        chatType: ChatType = .single,
        title: String? = nil,
        messages: [Message] = []
    ) {
        self.id = id
        self.agentConfiguration = agentConfiguration
        self.chatType = chatType
        self.title = title ?? agentConfiguration.name
        self.isMemoryEnabled = agentConfiguration.memoryEnabled
        self.messages = messages
        self.createdAt = Date()
        self.lastActivity = Date()
        self.groupTemplate = nil
        
        // Valori derivati dalla configurazione
        self.agentType = .custom // Nuovo tipo per agenti configurabili
        self.provider = AssistantProvider.fromString(agentConfiguration.preferredProvider)
        self.selectedModel = nil
        self.n8nWorkflow = nil
    }
    
    // Inizializzatore per chat di gruppo
    init(
        id: UUID = UUID(),
        agentType: AgentType,
        chatType: ChatType,
        title: String,
        groupTemplate: AgentGroupTemplate? = nil,
        messages: [Message] = []
    ) {
        self.id = id
        self.agentType = agentType
        self.chatType = chatType
        self.title = title
        self.groupTemplate = groupTemplate
        self.messages = messages
        self.createdAt = Date()
        self.lastActivity = Date()
        
        // Valori di default
        self.agentConfiguration = nil
        self.provider = nil
        self.selectedModel = nil
        self.n8nWorkflow = nil
        self.isMemoryEnabled = true
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
            AgentMemoryManager.shared.analyzeAndStoreMessage(
                message,
                for: agentConfig.id,
                chatId: id
            )
        }
    }
    
    // Ottieni il contesto di memoria per questa chat
    func getMemoryContext() -> MemoryContext? {
        guard isMemoryEnabled, let agentConfig = agentConfiguration else { return nil }
        return AgentMemoryManager.shared.getMemoryContext(for: agentConfig.id, chatId: id)
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

    // MARK: - Codable
    enum CodingKeys: String, CodingKey {
        case id
        case messages
        case agentType
        case provider
        case selectedModel
        case n8nWorkflow
        case agentConfiguration
        case chatType
        case title
        case isMemoryEnabled
        case createdAt
        case lastActivity
        case groupTemplate
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        agentType = try container.decode(AgentType.self, forKey: .agentType)
        provider = try container.decodeIfPresent(AssistantProvider.self, forKey: .provider)
        n8nWorkflow = try container.decodeIfPresent(N8NWorkflow.self, forKey: .n8nWorkflow)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        groupTemplate = try container.decodeIfPresent(AgentGroupTemplate.self, forKey: .groupTemplate)
        
        // Inizializza le proprietà @Published direttamente con i valori decodificati
        let decodedMessages = try container.decode([Message].self, forKey: .messages)
        let decodedSelectedModel = try container.decodeIfPresent(String.self, forKey: .selectedModel)
        let decodedAgentConfiguration = try container.decodeIfPresent(AgentConfiguration.self, forKey: .agentConfiguration)
        let decodedChatType = try container.decodeIfPresent(ChatType.self, forKey: .chatType) ?? .single
        let decodedTitle = try container.decodeIfPresent(String.self, forKey: .title) ?? agentType.displayName
        let decodedIsMemoryEnabled = try container.decodeIfPresent(Bool.self, forKey: .isMemoryEnabled) ?? true
        let decodedLastActivity = try container.decodeIfPresent(Date.self, forKey: .lastActivity) ?? Date()
        
        self._messages = Published(initialValue: decodedMessages)
        self._selectedModel = Published(initialValue: decodedSelectedModel)
        self._agentConfiguration = Published(initialValue: decodedAgentConfiguration)
        self._chatType = Published(initialValue: decodedChatType)
        self._title = Published(initialValue: decodedTitle)
        self._isMemoryEnabled = Published(initialValue: decodedIsMemoryEnabled)
        self._lastActivity = Published(initialValue: decodedLastActivity)
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
    }
}