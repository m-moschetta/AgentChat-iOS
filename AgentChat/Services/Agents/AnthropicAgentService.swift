//
//  AnthropicAgentService.swift
//  AgentChat
//
//  Created by Agent on 2024-01-XX.
//

import Foundation



// MARK: - Anthropic Data Models
// Anthropic models are defined in ProviderModels.swift

// MARK: - Anthropic Agent Service
class AnthropicAgentService: BaseAgentService {
    private let httpService: BaseHTTPService
    
    override var supportedModels: [String] {
        return [
            "claude-opus-4-20250514",
            "claude-sonnet-4-20250514",
            "claude-opus-4-20250514-thinking",
            "claude-sonnet-4-20250514-thinking",
            "claude-3-7-sonnet-20250219",
            "claude-3-7-sonnet-latest",
            "claude-3-5-sonnet-20241022",
            "claude-3-5-sonnet-latest",
            "claude-3-5-haiku-20241022",
            "claude-3-5-haiku-latest",
            "claude-3-opus-20240229",
            "claude-3-sonnet-20240229",
            "claude-3-haiku-20240307"
        ]
    }
    
    override var providerName: String {
        return "Anthropic"
    }
    
    override var capabilities: [AgentCapability] {
        return [.textGeneration, .codeGeneration, .dataAnalysis]
    }
    
    override init(configuration: AgentConfiguration? = nil) {
        let config = configuration ?? AgentConfiguration(
            id: UUID(),
            name: "Claude Assistant",
            systemPrompt: "You are Claude, an AI assistant created by Anthropic. You are helpful, harmless, and honest.",
            personality: "helpful, harmless, and honest",
            role: "AI assistant",
            icon: "🤖",
            preferredProvider: "Anthropic",
            temperature: 0.7,
            maxTokens: 4000,
            isActive: true,
            memoryEnabled: true,
            contextWindow: 10,
            model: "claude-sonnet-4-20250514",
            capabilities: [.textGeneration, .codeGeneration, .dataAnalysis]
        )
        
        self.httpService = BaseHTTPService(
            configuration: .anthropic,
            requestTransformer: AnthropicRequestTransformer(),
            responseParser: AnthropicResponseParser()
        )
        
        super.init(configuration: config)
    }
    
    override func sendMessage(_ message: String, model: String?) async throws -> String {
        let selectedModel = model ?? self.agentConfiguration?.model ?? "claude-sonnet-4-20250514"
        
        let unifiedRequest = UnifiedChatRequest(
            model: selectedModel,
            messages: [ChatMessage(role: "user", content: message)],
            parameters: RequestParameters(
                temperature: self.agentConfiguration?.temperature,
                maxTokens: self.agentConfiguration?.maxTokens
            )
        )
        
        let response = try await httpService.sendUnifiedRequest(unifiedRequest)
        
        // Save memory
        if let agentId = agentConfiguration?.id {
            try await AgentMemoryManager.shared.saveMemory(
                for: agentId,
                chatId: UUID(),
                content: response.content,
                type: .conversationContext,
                metadata: ["model": response.model ?? "unknown"]
            )
        }
        
        return response.content
    }
    

    
    // MARK: - Anthropic-specific methods
    func sendMessageWithCustomParameters(
        _ message: String,
        context: [ChatMessage],
        temperature: Double? = nil,
        maxTokens: Int? = nil,
        topP: Double? = nil,
        systemPrompt: String? = nil
    ) async throws -> String {
        let parameters = RequestParameters(
            temperature: temperature ?? self.agentConfiguration?.temperature,
            maxTokens: maxTokens ?? self.agentConfiguration?.maxTokens
        )
        
        let unifiedRequest = UnifiedChatRequest(
            model: self.agentConfiguration?.model ?? "claude-sonnet-4-20250514",
            messages: context + [ChatMessage(role: "user", content: message)],
            parameters: parameters
        )
        
        let response = try await httpService.sendUnifiedRequest(unifiedRequest)
        return response.content
    }
    
    func getModelInfo() -> [String: Any] {
        return [
            "provider": providerName,
            "supportedModels": supportedModels,
            "defaultModel": "claude-3-5-sonnet-20241022",
            "capabilities": Array(capabilities).map { $0.rawValue },
            "maxTokens": 200000,
            "contextWindow": 200000
        ]
    }
}