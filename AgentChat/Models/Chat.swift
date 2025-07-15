//
//  Chat.swift
//  AgentChat
//
//  Created by Mario Moschetta on 04/07/25.
//

import Foundation
import Combine

// MARK: - Chat
class Chat: Identifiable, ObservableObject, Hashable, Codable {
    let id: UUID
    @Published var messages: [Message]
    let agentType: AgentType
    let provider: AssistantProvider?
    @Published var selectedModel: String?
    let n8nWorkflow: N8NWorkflow?
    
    init(id: UUID = UUID(), agentType: AgentType, messages: [Message] = [], provider: AssistantProvider? = nil, selectedModel: String? = nil, n8nWorkflow: N8NWorkflow? = nil) {
        self.id = id
        self.agentType = agentType
        self.provider = provider
        self.n8nWorkflow = n8nWorkflow
        self.messages = messages
        self.selectedModel = selectedModel
    }
    
    var lastMessage: Message? {
        return messages.last
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
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        messages = try container.decode([Message].self, forKey: .messages)
        agentType = try container.decode(AgentType.self, forKey: .agentType)
        provider = try container.decodeIfPresent(AssistantProvider.self, forKey: .provider)
        selectedModel = try container.decodeIfPresent(String.self, forKey: .selectedModel)
        n8nWorkflow = try container.decodeIfPresent(N8NWorkflow.self, forKey: .n8nWorkflow)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(messages, forKey: .messages)
        try container.encode(agentType, forKey: .agentType)
        try container.encodeIfPresent(provider, forKey: .provider)
        try container.encodeIfPresent(selectedModel, forKey: .selectedModel)
        try container.encodeIfPresent(n8nWorkflow, forKey: .n8nWorkflow)
    }
}