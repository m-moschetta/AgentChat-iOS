//
//  Chat.swift
//  AgentChat
//
//  Created by Mario Moschetta on 04/07/25.
//

import Foundation
import Combine

// MARK: - Chat
class Chat: Identifiable, ObservableObject, Hashable {
    let id: UUID
    @Published var messages: [Message]
    let agentType: AgentType
    let provider: AssistantProvider?
    @Published var agents: [AssistantProvider]
    @Published var selectedModel: String?
    let n8nWorkflow: N8NWorkflow?

    init(id: UUID = UUID(), agentType: AgentType, messages: [Message] = [], provider: AssistantProvider? = nil, agents: [AssistantProvider] = [], selectedModel: String? = nil, n8nWorkflow: N8NWorkflow? = nil) {
        self.id = id
        self.agentType = agentType
        self.provider = provider
        self.agents = agents
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
}