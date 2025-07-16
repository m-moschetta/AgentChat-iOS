//
//  DeepSeekAgentService.swift
//  AgentChat
//
//  Created by Agent on 2024-01-XX.
//

import Foundation

// MARK: - DeepSeek Request Transformer
class DeepSeekRequestTransformer: RequestTransformer {
    func transform(_ request: UnifiedChatRequest) throws -> Data {
        var deepSeekRequest: [String: Any] = [
            "model": request.model,
            "messages": request.messages.map { message in
                [
                    "role": message.role,
                    "content": message.content
                ]
            }
        ]
        
        if let temperature = request.parameters.temperature {
            deepSeekRequest["temperature"] = temperature
        }
        
        if let maxTokens = request.parameters.maxTokens {
            deepSeekRequest["max_tokens"] = maxTokens
        }
        
        if let topP = request.parameters.topP {
            deepSeekRequest["top_p"] = topP
        }
        
        // DeepSeek specific parameters
        deepSeekRequest["stream"] = false
        
        return try JSONSerialization.data(withJSONObject: deepSeekRequest)
    }
}

// MARK: - DeepSeek Response Parser
class DeepSeekResponseParser: ResponseParser {
    func parse(_ data: Data) throws -> UnifiedChatResponse {
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        guard let json = json else {
            throw ChatServiceError.invalidResponse
        }
        
        if let error = json["error"] as? [String: Any],
           let message = error["message"] as? String {
            throw ChatServiceError.serverError(message)
        }
        
        guard let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw ChatServiceError.invalidResponse
        }
        
        let usage = TokenUsage(
            promptTokens: (json["usage"] as? [String: Any])?["prompt_tokens"] as? Int ?? 0,
            completionTokens: (json["usage"] as? [String: Any])?["completion_tokens"] as? Int ?? 0,
            totalTokens: (json["usage"] as? [String: Any])?["total_tokens"] as? Int
        )
        
        return UnifiedChatResponse(
            content: content,
            model: json["model"] as? String ?? "deepseek-unknown",
            usage: usage
        )
    }
}

// MARK: - DeepSeek Agent Service
class DeepSeekAgentService: BaseAgentService {
    private let httpService: BaseHTTPService
    
    override var supportedModels: [String] {
        return [
            "deepseek-v3-0324",
            "deepseek-r1-0528",
            "deepseek-r1-lite-preview",
            "deepseek-r1-distill-llama-70b",
            "deepseek-r1-distill-qwen-32b",
            "deepseek-r1-distill-qwen-14b",
            "deepseek-r1-distill-qwen-7b",
            "deepseek-r1-distill-qwen-1.5b",
            "deepseek-coder-v2-instruct",
            "deepseek-coder-v2-lite-instruct",
            "deepseek-math-7b-instruct"
        ]
    }
    
    override var providerName: String {
        return "DeepSeek"
    }
    
    override var capabilities: [AgentCapability] {
        return [.textGeneration, .codeGeneration, .dataAnalysis]
    }
    
    override init(configuration: AgentConfiguration? = nil) {
        let config = configuration ?? AgentConfiguration(
            id: UUID(),
            name: "DeepSeek Assistant",
            systemPrompt: "You are DeepSeek, an AI assistant with strong reasoning and coding capabilities. You excel at complex problem-solving, mathematics, and programming tasks.",
            personality: "Analytical, precise, and methodical",
            role: "AI Assistant",
            icon: "🧠",
            preferredProvider: ProviderType.deepSeek.rawValue
        )
        
        self.httpService = BaseHTTPService(
            configuration: .deepSeek,
            requestTransformer: DeepSeekRequestTransformer(),
            responseParser: DeepSeekResponseParser()
        )
        
        super.init(configuration: config)
    }
    
    override func sendMessage(_ message: String, model: String?) async throws -> String {
        let selectedModel = model ?? agentConfiguration?.model ?? "deepseek-v3-0324"
        
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
        
        // Save conversation context using memory manager
        if let agentId = agentConfiguration?.id {
            AgentMemoryManager.shared.saveMemory(
                for: agentId,
                chatId: UUID(),
                content: response.content,
                type: .conversationContext,
                metadata: ["model": response.model]
            )
        }
        
        return response.content
    }
    

    
    // MARK: - DeepSeek-specific methods
    func sendMessageWithReasoning(
        _ message: String,
        context: [ChatMessage],
        useReasoningModel: Bool = true
    ) async throws -> String {
        let model = useReasoningModel ? "deepseek-r1-0528" : agentConfiguration?.model ?? "deepseek-v3-0324"
        
        let unifiedRequest = UnifiedChatRequest(
            model: model,
            messages: context + [ChatMessage(role: "user", content: message)],
            parameters: RequestParameters(
                temperature: agentConfiguration?.temperature,
                maxTokens: agentConfiguration?.maxTokens,
                topP: nil
            )
        )
        
        let response = try await httpService.sendUnifiedRequest(unifiedRequest)
        return response.content
    }
    
    func sendCodingMessage(
        _ message: String,
        context: [ChatMessage],
        useCodingModel: Bool = true
    ) async throws -> String {
        let model = useCodingModel ? "deepseek-coder-v2-instruct" : agentConfiguration?.model ?? "deepseek-v3-0324"
        
        let unifiedRequest = UnifiedChatRequest(
            model: model,
            messages: context + [ChatMessage(role: "user", content: message)],
            parameters: RequestParameters(
                temperature: agentConfiguration?.temperature ?? 0.1,
                maxTokens: agentConfiguration?.maxTokens,
                topP: nil
            )
        )
        
        let response = try await httpService.sendUnifiedRequest(unifiedRequest)
        return response.content
    }
    
    func sendMathMessage(
        _ message: String,
        context: [ChatMessage]
    ) async throws -> String {
        let unifiedRequest = UnifiedChatRequest(
            model: "deepseek-math-7b-instruct",
            messages: context + [ChatMessage(role: "user", content: message)],
            parameters: RequestParameters(
                temperature: agentConfiguration?.temperature ?? 0.1,
                maxTokens: agentConfiguration?.maxTokens,
                topP: nil
            )
        )
        
        let response = try await httpService.sendUnifiedRequest(unifiedRequest)
        return response.content
    }
    
    func getModelInfo() -> [String: Any] {
        return [
            "provider": providerName,
            "supportedModels": supportedModels,
            "defaultModel": "deepseek-v3-0324",
            "capabilities": capabilities.map { $0.rawValue },
            "reasoningModel": "deepseek-r1-0528",
            "codingModel": "deepseek-coder-v2-instruct",
            "mathModel": "deepseek-math-7b-instruct",
            "contextWindow": 128000,
            "openSource": true
        ]
    }
}