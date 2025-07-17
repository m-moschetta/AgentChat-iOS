//
//  GrokAgentService.swift
//  AgentChat
//
//  Created by Agent on 2024-01-XX.
//

import Foundation



// MARK: - Grok Agent Service
class GrokAgentService: BaseAgentService {
    private let httpService: BaseHTTPService
    
    override var supportedModels: [String] {
        return [
            "grok-3",
            "grok-2-1212",
            "grok-2-vision-1212",
            "grok-2-public",
            "grok-beta",
            "grok-vision-beta"
        ]
    }
    
    override var providerName: String {
        return "Grok"
    }
    
    override var capabilities: [AgentCapability] {
        return [.textGeneration, .codeGeneration, .dataAnalysis]
    }
    
    override init(configuration: AgentConfiguration? = nil, memoryManager: AgentMemoryManager? = nil) {
        let config = configuration ?? AgentConfiguration(
            id: UUID(),
            name: "Grok Assistant",
            systemPrompt: "You are Grok, an AI assistant created by xAI. You have access to real-time information and can provide up-to-date responses.",
            personality: "Witty, informative, real-time aware",
            role: "AI Assistant",
            icon: "🤖",
            preferredProvider: "Grok",
            temperature: 0.7,
            maxTokens: 4000,
            isActive: true,
            memoryEnabled: true,
            contextWindow: 10,
            model: "grok-2-1212",
            capabilities: [.textGeneration, .codeGeneration, .dataAnalysis]
        )
        
        self.httpService = BaseHTTPService(
            configuration: .grok,
            requestTransformer: GrokRequestTransformer(),
            responseParser: GrokResponseParser()
        )
        
        super.init(configuration: config, memoryManager: memoryManager)
    }
    
    override func sendMessage(_ message: String, model: String?) async throws -> String {
        let selectedModel = model ?? agentConfiguration?.model ?? "grok-2-1212"
        
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
            memoryManager.saveMemory(
                for: agentId,
                chatId: UUID(),
                content: response.content,
                type: .conversationContext,
                metadata: ["model": selectedModel]
            )
        }
        
        return response.content
    }
    
    // MARK: - Grok-specific methods
    func sendMessageWithRealTimeData(
        _ message: String,
        model: String? = nil,
        includeRealTimeData: Bool = true
    ) async throws -> String {
        var enhancedMessage = message
        
        if includeRealTimeData {
            enhancedMessage += "\n\nPlease use your real-time data access to provide the most current information available."
        }
        
        return try await sendMessage(enhancedMessage, model: model)
    }
    
    func getModelInfo() -> [String: Any] {
        return [
            "provider": providerName,
            "supportedModels": supportedModels,
            "defaultModel": "grok-beta",
            "capabilities": capabilities.map { $0.rawValue },
            "realTimeAccess": true,
            "contextWindow": 131072
        ]
    }
}