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

    case deepSeek = "deepseek"
    case n8n = "n8n"
    case custom = "custom"
    
    var displayName: String {
        switch self {
        case .openai: return "OpenAI"
        case .anthropic: return "Anthropic"
        case .mistral: return "Mistral"
        case .perplexity: return "Perplexity"
        case .grok: return "Grok"

        case .deepSeek: return "DeepSeek"
        case .n8n: return "n8n"
        case .custom: return "Custom"
        }
    }
}

// MARK: - Assistant Provider
struct AssistantProvider: Codable, Identifiable, Equatable, Hashable {
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
            supportedModels: [
                // GPT-4 Omni Series
                "gpt-4o", "gpt-4o-latest",
                // GPT-4.1 Series
                "gpt-4.1", "gpt-4.1-mini",
                // Reasoning Models (o-series)
                "o1", "o1-mini", "o1-pro",
                "o3", "o3-pro",
                "o4-mini",
                // Legacy Models
                "gpt-3.5-turbo",
                // Embedding Models
                "text-embedding-3-large", "text-embedding-3-small", "text-embedding-ada-002"
            ],
            defaultModel: "gpt-4o-latest",
            icon: "brain.head.profile",
            description: "OpenAI's latest models including GPT-4o, GPT-4.1, and o-series reasoning models"
        ),
        AssistantProvider(
            name: "Anthropic",
            type: .anthropic,
            endpoint: "https://api.anthropic.com/v1/messages",
            supportedModels: [
                // Claude 4 Series
                "claude-opus-4", "claude-sonnet-4",
                // Claude 3.5 Series
                "claude-3.5-sonnet", "claude-3.5-haiku",
                // Claude 3.7 Series
                "claude-3.7-sonnet",
                // Claude Original Series
                "claude-3-opus", "claude-3-sonnet", "claude-3-haiku"
            ],
            defaultModel: "claude-3.5-sonnet",
            icon: "sparkles",
            description: "Anthropic's Claude models for thoughtful and helpful conversations"
        ),
        AssistantProvider(
            name: "Mistral",
            type: .mistral,
            endpoint: "https://api.mistral.ai/v1/chat/completions",
            supportedModels: [
                // Modelli Pro
                "mistral-large-latest", "mistral-small-latest", "mistral-large-specific",
                // Specializzati
                "devstral-medium", "magistral-reasoning", "pixtral-vision", "voxtral-audio",
                // Open-Source
                "open-mistral-7b", "open-mixtral-8x7b", "open-mixtral-8x22b"
            ],
            defaultModel: "mistral-large-latest",
            icon: "wind",
            description: "Mistral's efficient and powerful language models with specialized capabilities"
        ),
        AssistantProvider(
            name: "Perplexity",
            type: .perplexity,
            endpoint: "https://api.perplexity.ai/chat/completions",
            supportedModels: [
                // Sonar Online
                "sonar-pro", "llama-sonar-huge-online", "llama-sonar-large-online",
                // Sonar Specializzati
                "sonar-reasoning-pro", "sonar-deep-research",
                // Open-Source
                "llama-405b-instruct", "llama-70b-instruct", "mixtral-8x7b-instruct"
            ],
            defaultModel: "sonar-pro",
            icon: "magnifyingglass.circle",
            description: "Perplexity's search-enhanced AI models with reasoning and research capabilities"
        ),
        AssistantProvider(
            name: "Grok",
            type: .grok,
            endpoint: "https://api.x.ai/v1/chat/completions",
            supportedModels: [
                // Grok 4
                "grok-4", "grok-4-specific",
                // Grok 1.5
                "grok-1.5", "grok-1.5-vision"
            ],
            defaultModel: "grok-4",
            icon: "bolt.circle",
            description: "xAI's Grok models with advanced reasoning and vision capabilities"
        ),

        AssistantProvider(
            name: "DeepSeek",
            type: .deepSeek,
            endpoint: "https://api.deepseek.com/v1/chat/completions",
            supportedModels: [
                // Modelli R1 (Ragionamento)
                "deepseek-r1-0528", "deepseek-r1", "deepseek-r1-distill-32b", "deepseek-r1-distill-70b",
                // Modelli V3
                "deepseek-v3-0324", "deepseek-v3",
                // Modelli Specializzati
                "deepseek-coder-v2", "deepseek-math"
            ],
            defaultModel: "deepseek-r1-0528",
            icon: "brain.filled.head.profile",
            description: "DeepSeek's open-source models with R1 reasoning, V3 series, and specialized coding/math capabilities (Luglio 2025)"
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