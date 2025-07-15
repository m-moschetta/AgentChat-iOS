//
//  Agent.swift
//  AgentChat
//
//  Created by Codex on 2025.
//

import Foundation

/// Simple representation of a chat agent.
struct Agent: Identifiable, Hashable {
    let id: UUID
    let provider: AssistantProvider
    var model: String?

    init(id: UUID = UUID(), provider: AssistantProvider, model: String? = nil) {
        self.id = id
        self.provider = provider
        self.model = model
    }

    var name: String { provider.name }

    var agentType: AgentType {
        switch provider.type {
        case .openai: return .openAI
        case .anthropic: return .claude
        case .mistral: return .mistral
        case .perplexity: return .perplexity
        case .grok: return .grok
        case .n8n: return .n8n
        case .custom: return .custom
        }
    }
}
