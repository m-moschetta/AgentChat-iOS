//
//  AssistantProvider.swift
//  AgentChat
//
//  Created by Mario Moschetta on 04/07/25.
//

import Foundation

// MARK: - Provider Type
enum ProviderType: String, Codable, CaseIterable {
    case openai = "openai"
    case anthropic = "anthropic"
    case mistral = "mistral"
    case perplexity = "perplexity"
    case grok = "grok"
    case n8n = "n8n"
    case custom = "custom"
    
    var displayName: String {
        switch self {
        case .openai: return "OpenAI"
        case .anthropic: return "Anthropic"
        case .mistral: return "Mistral"
        case .perplexity: return "Perplexity"
        case .grok: return "Grok"
        case .n8n: return "n8n"
        case .custom: return "Custom"
        }
    }
}

// MARK: - Assistant Provider
struct AssistantProvider: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let type: ProviderType
    let endpoint: String
    let apiKeyRequired: Bool
    let supportedModels: [String]
    let defaultModel: String?
    let icon: String
    let description: String
    let isActive: Bool
    
    init(id: String = UUID().uuidString, name: String, type: ProviderType, endpoint: String, apiKeyRequired: Bool = true, supportedModels: [String], defaultModel: String? = nil, icon: String, description: String, isActive: Bool = true) {
        self.id = id
        self.name = name
        self.type = type
        self.endpoint = endpoint
        self.apiKeyRequired = apiKeyRequired
        self.supportedModels = supportedModels
        self.defaultModel = defaultModel ?? supportedModels.first
        self.icon = icon
        self.description = description
        self.isActive = isActive
    }
    
    static func == (lhs: AssistantProvider, rhs: AssistantProvider) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Helper Methods
extension AssistantProvider {
    static func fromString(_ providerName: String) -> AssistantProvider? {
        return defaultProviders.first { provider in
            provider.name.lowercased() == providerName.lowercased() ||
            provider.type.displayName.lowercased() == providerName.lowercased()
        }
    }
}

// MARK: - Default Providers
extension AssistantProvider {
    static let defaultProviders: [AssistantProvider] = [
        AssistantProvider(
            name: "OpenAI",
            type: .openai,
            endpoint: "https://api.openai.com/v1/chat/completions",
            supportedModels: ["o3", "o4-mini", "gpt-4.1", "gpt-4.1-mini", "gpt-4.1-nano", "gpt-4o", "gpt-4o-mini", "o1", "o1-mini"],
            defaultModel: "o3",
            icon: "brain.head.profile",
            description: "OpenAI's latest models including o3 reasoning and GPT-4.1 series (2025)"
        ),
        AssistantProvider(
            name: "Anthropic",
            type: .anthropic,
            endpoint: "https://api.anthropic.com/v1/messages",
            supportedModels: ["claude-opus-4-20250514", "claude-sonnet-4-20250514", "claude-3-7-sonnet-20250219", "claude-3-5-sonnet-20241022", "claude-3-5-haiku-20241022", "claude-3-opus-20240229", "claude-3-haiku-20240307"],
            defaultModel: "claude-3-5-sonnet-20241022",
            icon: "sparkles",
            description: "Anthropic's Claude models for thoughtful and helpful conversations"
        ),
        AssistantProvider(
            name: "Mistral",
            type: .mistral,
            endpoint: "https://api.mistral.ai/v1/chat/completions",
            supportedModels: ["mistral-large-latest", "mistral-medium-latest", "mistral-small-latest", "codestral-latest", "pixtral-large-latest", "ministral-8b-latest", "ministral-3b-latest"],
            defaultModel: "mistral-large-latest",
            icon: "wind",
            description: "Mistral's efficient and powerful language models"
        ),
        AssistantProvider(
            name: "Perplexity",
            type: .perplexity,
            endpoint: "https://api.perplexity.ai/chat/completions",
            supportedModels: ["sonar-pro", "sonar", "sonar-reasoning-pro", "sonar-reasoning", "sonar-deep-research", "sonar-large"],
            defaultModel: "sonar-reasoning-pro",
            icon: "magnifyingglass.circle",
            description: "Perplexity's latest search-enhanced AI models with reasoning and deep research (2025)"
        ),
        AssistantProvider(
            name: "Grok",
            type: .grok,
            endpoint: "https://api.x.ai/v1/chat/completions",
            supportedModels: ["grok-4", "grok-3", "grok-3-mini", "grok-2-image-1212"],
            defaultModel: "grok-4",
            icon: "bolt.circle",
            description: "xAI's Grok models with reasoning capabilities and real-time information"
        ),
        AssistantProvider(
            name: "n8n Blog Creator",
            type: .n8n,
            endpoint: "https://your-n8n-instance.com/webhook/blog-creation",
            apiKeyRequired: false,
            supportedModels: ["blog-workflow"],
            defaultModel: "blog-workflow",
            icon: "doc.text",
            description: "Automated blog creation and publishing workflow via n8n"
        )
    ]
}