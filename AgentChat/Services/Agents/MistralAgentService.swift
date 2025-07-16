//
//  MistralAgentService.swift
//  AgentChat
//
//  Created by Agent on 2024-01-XX.
//

import Foundation



// MARK: - Mistral Agent Service
class MistralAgentService: BaseAgentService {
    private let httpService: BaseHTTPService
    
    override var supportedModels: [String] {
        return [
            "mistral-medium-2505",
            "magistral-medium-2506",
            "codestral-2501",
            "devstral-medium-2507",
            "mistral-large-2411",
            "pixtral-large-2411",
            "ministral-8b-2410",
            "ministral-3b-2410",
            "magistral-small-2506",
            "mistral-small-2506",
            "devstral-small-2507",
            "mistral-nemo-2407",
            "pixtral-12b-2409",
            "mistral-embed",
            "mistral-moderation-2411",
            "mistral-ocr-2505"
        ]
    }
    
    override var providerName: String {
        return "Mistral"
    }
    
    override var capabilities: [AgentCapability] {
        return [.textGeneration, .codeGeneration, .dataAnalysis]
    }
    
    override init(configuration: AgentConfiguration? = nil) {
        let config = configuration ?? AgentConfiguration(
            id: UUID(),
            name: "Mistral Assistant",
            systemPrompt: "You are a helpful AI assistant powered by Mistral AI.",
            personality: "helpful and analytical",
            role: "AI assistant",
            icon: "🧠",
            preferredProvider: "Mistral",
            temperature: 0.7,
            maxTokens: 4000,
            isActive: true,
            memoryEnabled: true,
            contextWindow: 10,
            model: "mistral-medium-2505",
            capabilities: [.textGeneration, .codeGeneration, .dataAnalysis]
        )
        
        self.httpService = BaseHTTPService(
            configuration: .mistral,
            requestTransformer: MistralRequestTransformer(),
            responseParser: MistralResponseParser()
        )
        
        super.init(configuration: config)
    }
    
    override func sendMessage(_ message: String, model: String?) async throws -> String {
        let selectedModel = model ?? agentConfiguration?.model ?? "mistral-medium-2505"
        
        let unifiedRequest = UnifiedChatRequest(
            model: selectedModel,
            messages: [ChatMessage(role: "user", content: message)],
            parameters: RequestParameters(
                temperature: agentConfiguration?.temperature,
                maxTokens: agentConfiguration?.maxTokens,
                topP: nil
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
    

}