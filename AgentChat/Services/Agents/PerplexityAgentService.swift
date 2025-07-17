//
//  PerplexityAgentService.swift
//  AgentChat
//
//  Created by Agent on 2024-01-XX.
//

import Foundation

// MARK: - Perplexity Request/Response Transformers
// Perplexity transformers are defined in BaseHTTPService.swift

// MARK: - Perplexity Agent Service
class PerplexityAgentService: BaseAgentService {
    private let httpService: BaseHTTPService
    
    override var supportedModels: [String] {
        return [
            "sonar-reasoning-pro",
            "sonar-reasoning",
            "sonar-pro",
            "sonar",
            "sonar-deep-research",
            "r1-1776",
            "llama-3.1-sonar-large-128k-online",
            "llama-3.1-sonar-small-128k-online",
            "llama-3.1-sonar-large-128k-chat",
            "llama-3.1-sonar-small-128k-chat",
            "llama-3.1-8b-instruct",
            "llama-3.1-70b-instruct"
        ]
    }
    
    override var providerName: String {
        return "Perplexity"
    }
    
    override var capabilities: [AgentCapability] {
        return [.textGeneration, .codeGeneration, .dataAnalysis]
    }
    
    override init(configuration: AgentConfiguration? = nil, memoryManager: AgentMemoryManager? = nil) {
        let config = configuration ?? AgentConfiguration(
            id: UUID(),
            name: "Perplexity Assistant",
            systemPrompt: "You are a helpful AI assistant powered by Perplexity AI. You have access to real-time web search and can provide up-to-date information from the internet.",
            personality: "Informativo e preciso",
            role: "Assistente di ricerca",
            icon: "🔍",
            preferredProvider: "Perplexity",
            temperature: 0.7,
            maxTokens: 4000,
            isActive: true,
            memoryEnabled: true,
            contextWindow: 10,
            model: "sonar-pro",
            capabilities: [.textGeneration, .codeGeneration, .dataAnalysis]
        )
        
        self.httpService = BaseHTTPService(
            configuration: .perplexity,
            requestTransformer: PerplexityRequestTransformer(),
            responseParser: PerplexityResponseParser()
        )
        
        super.init(configuration: config, memoryManager: memoryManager)
    }
    
    override func sendMessage(_ message: String, model: String?) async throws -> String {
        let selectedModel = model ?? agentConfiguration?.model ?? "sonar-pro"
        
        let unifiedRequest = UnifiedChatRequest(
            model: selectedModel,
            messages: [ChatMessage(role: "user", content: message)],
            parameters: RequestParameters(
                temperature: agentConfiguration?.temperature,
                maxTokens: agentConfiguration?.maxTokens
            )
        )
        
        let response = try await httpService.sendUnifiedRequest(unifiedRequest)
        
        // Save memory
        if let agentId = agentConfiguration?.id {
            memoryManager.saveMemory(
                for: agentId,
                chatId: UUID(),
                content: response.content,
                type: .conversationContext,
                metadata: ["model": response.model ?? "unknown"]
            )
        }
        
        return response.content
    }
    

    
    // MARK: - Perplexity-specific methods
    func sendMessageWithWebSearch(
        _ message: String,
        context: [ChatMessage],
        enableWebSearch: Bool = true
    ) async throws -> String {
        let model = enableWebSearch ? "sonar-pro" : "sonar"
        
        let unifiedRequest = UnifiedChatRequest(
            model: model,
            messages: context + [ChatMessage(role: "user", content: message)],
            parameters: RequestParameters(
                temperature: agentConfiguration?.temperature,
                maxTokens: agentConfiguration?.maxTokens
            )
        )
        
        let response = try await httpService.sendUnifiedRequest(unifiedRequest)
        return response.content
    }
    
    func searchAndAnswer(_ query: String, context: [ChatMessage] = []) async throws -> String {
        let searchMessage = "Please search for and provide information about: \(query)"
        return try await sendMessageWithWebSearch(searchMessage, context: context, enableWebSearch: true)
    }
    
    func getModelInfo() -> [String: Any] {
        return [
            "provider": providerName,
            "supportedModels": supportedModels,
            "defaultModel": "llama-3.1-sonar-large-128k-online",
            "capabilities": capabilities.map { $0.rawValue },
            "webSearchEnabled": true,
            "realTimeAccess": true,
            "contextWindow": 131072
        ]
    }
}