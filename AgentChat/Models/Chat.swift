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
struct Chat: Identifiable, Hashable, Codable {
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
         groupTemplate: AgentGroupTemplate? = nil) {
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
    }
    
    // Inizializzatore da ChatEntity
    init(from entity: ChatEntity) {
        let decoder = JSONDecoder()

        self.id = entity.id ?? UUID()
        self.agentType = AgentType(rawValue: entity.agentTypeString ?? "") ?? .openAI
        self.chatType = ChatType(rawValue: entity.chatTypeString ?? "") ?? .single
        self.title = entity.title ?? ""
        self.isMemoryEnabled = entity.isMemoryEnabled
        self.createdAt = entity.createdAt ?? Date()
        self.lastActivity = entity.lastActivity ?? Date()
        self.selectedModel = entity.selectedModel

        self.messages = (entity.messages as? Set<MessageEntity> ?? []).map { Message(from: $0) }.sorted(by: { $0.timestamp < $1.timestamp })

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
    mutating func updateLastActivity() {
        lastActivity = Date()
    }
    
    // Aggiungi un messaggio e aggiorna l'attività
    mutating func addMessage(_ message: Message) {
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


}