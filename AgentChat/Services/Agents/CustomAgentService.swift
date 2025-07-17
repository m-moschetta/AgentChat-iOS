//
//  CustomAgentService.swift
//  AgentChat
//
//  Created by Agent on 2024-01-XX.
//

import Foundation

// MARK: - Custom Provider Configuration
struct CustomProviderConfig: Codable {
    let name: String
    let baseURL: String
    let apiKey: String?
    let headers: [String: String]
    let requestFormat: RequestFormat
    let responseFormat: ResponseFormat
    let supportedModels: [String]
    let capabilities: [String]
    
    enum RequestFormat: String, Codable {
        case openAICompatible = "openai"
        case anthropicCompatible = "anthropic"
        case custom = "custom"
    }
    
    enum ResponseFormat: String, Codable {
        case openAICompatible = "openai"
        case anthropicCompatible = "anthropic"
        case custom = "custom"
    }
}

// MARK: - Custom Request Transformer
class CustomRequestTransformer: RequestTransformer {
    private let config: CustomProviderConfig
    
    init(config: CustomProviderConfig) {
        self.config = config
    }
    
    func transform(_ request: UnifiedChatRequest) throws -> Data {
        switch config.requestFormat {
        case .openAICompatible:
            return try transformToOpenAIFormat(request)
        case .anthropicCompatible:
            return try transformToAnthropicFormat(request)
        case .custom:
            return try transformToCustomFormat(request)
        }
    }
    
    private func transformToOpenAIFormat(_ request: UnifiedChatRequest) throws -> Data {
        var openAIRequest: [String: Any] = [
            "model": request.model,
            "messages": request.messages.map { message in
                [
                    "role": message.role,
                    "content": message.content
                ]
            }
        ]
        
        if let temperature = request.parameters.temperature {
            openAIRequest["temperature"] = temperature
        }
        
        if let maxTokens = request.parameters.maxTokens {
            openAIRequest["max_tokens"] = maxTokens
        }
        
        if let topP = request.parameters.topP {
            openAIRequest["top_p"] = topP
        }
        
        return try JSONSerialization.data(withJSONObject: openAIRequest)
    }
    
    private func transformToAnthropicFormat(_ request: UnifiedChatRequest) throws -> Data {
        var anthropicRequest: [String: Any] = [
            "model": request.model,
            "max_tokens": request.parameters.maxTokens ?? 4096,
            "messages": request.messages.map { message in
                [
                    "role": message.role,
                    "content": message.content
                ]
            }
        ]
        
        if let temperature = request.parameters.temperature {
            anthropicRequest["temperature"] = temperature
        }
        
        if let topP = request.parameters.topP {
            anthropicRequest["top_p"] = topP
        }
        
        // Removed systemPrompt as it's not in RequestParameters
        if let systemMessage = request.messages.first(where: { $0.role == "system" }) {
            anthropicRequest["system"] = systemMessage.content
        }
        
        return try JSONSerialization.data(withJSONObject: anthropicRequest)
    }
    
    private func transformToCustomFormat(_ request: UnifiedChatRequest) throws -> Data {
        // Default to OpenAI format for custom providers
        return try transformToOpenAIFormat(request)
    }
}

// MARK: - Custom Response Parser
enum ParsingError: Error {
    case invalidFormat
    case apiError(String)
    case missingContent
}

class CustomResponseParser: ResponseParser {
    private let config: CustomProviderConfig
    
    init(config: CustomProviderConfig) {
        self.config = config
    }
    
    func parse(_ data: Data) throws -> UnifiedChatResponse {
        switch config.responseFormat {
        case .openAICompatible:
            return try parseOpenAIFormat(data)
        case .anthropicCompatible:
            return try parseAnthropicFormat(data)
        case .custom:
            return try parseCustomFormat(data)
        }
    }
    
    private func parseOpenAIFormat(_ data: Data) throws -> UnifiedChatResponse {
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        guard let json = json else {
            throw ParsingError.invalidFormat
        }
        
        if let error = json["error"] as? [String: Any],
           let message = error["message"] as? String {
            throw ParsingError.apiError(message)
        }
        
        guard let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw ParsingError.missingContent
        }
        
        let usage = TokenUsage(
            promptTokens: (json["usage"] as? [String: Any])?["prompt_tokens"] as? Int ?? 0,
            completionTokens: (json["usage"] as? [String: Any])?["completion_tokens"] as? Int ?? 0,
            totalTokens: (json["usage"] as? [String: Any])?["total_tokens"] as? Int
        )
        
        return UnifiedChatResponse(
            content: content,
            model: json["model"] as? String ?? "unknown",
            usage: usage
        )
    }
    
    private func parseAnthropicFormat(_ data: Data) throws -> UnifiedChatResponse {
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        guard let json = json else {
            throw ParsingError.invalidFormat
        }
        
        if let error = json["error"] as? [String: Any],
           let message = error["message"] as? String {
            throw ParsingError.apiError(message)
        }
        
        guard let content = json["content"] as? [[String: Any]],
              let firstContent = content.first,
              let text = firstContent["text"] as? String else {
            throw ParsingError.missingContent
        }
        
        let usage = TokenUsage(
            promptTokens: (json["usage"] as? [String: Any])?["input_tokens"] as? Int ?? 0,
            completionTokens: (json["usage"] as? [String: Any])?["output_tokens"] as? Int ?? 0,
            totalTokens: nil
        )
        
        return UnifiedChatResponse(
            content: text,
            model: json["model"] as? String ?? "unknown",
            usage: usage
        )
    }
    
    private func parseCustomFormat(_ data: Data) throws -> UnifiedChatResponse {
        // Default to OpenAI format for custom providers
        return try parseOpenAIFormat(data)
    }
}

// MARK: - Custom Agent Service
class CustomAgentService: BaseAgentService {
    private let httpService: BaseHTTPService
    private let customConfig: CustomProviderConfig
    
    override var supportedModels: [String] {
        return customConfig.supportedModels
    }
    
    override var providerName: String {
        return customConfig.name
    }
    
    override var capabilities: [AgentCapability] {
        return customConfig.capabilities.compactMap { AgentCapability(rawValue: $0) }
    }
    
    init(configuration: AgentConfiguration? = nil, customConfig: CustomProviderConfig? = nil, memoryManager: AgentMemoryManager? = nil) {
        // Use provided custom config or create a default one
        self.customConfig = customConfig ?? CustomProviderConfig(
            name: "Custom Provider",
            baseURL: "https://api.example.com",
            apiKey: nil,
            headers: [:],
            requestFormat: .openAICompatible,
            responseFormat: .openAICompatible,
            supportedModels: ["custom-model"],
            capabilities: ["textGeneration", "conversational"]
        )
        
        let config = configuration ?? AgentConfiguration.createAgentConfiguration(
            name: self.customConfig.name,
            agentType: .custom,
            model: self.customConfig.supportedModels.first ?? "custom-model",
            systemPrompt: "You are a helpful AI assistant from a custom provider.",
            capabilities: [],
            parameters: nil
        )
        
        // Create custom provider configuration
        let providerConfig = ProviderConfiguration(
            name: self.customConfig.name,
            baseURL: self.customConfig.baseURL,
            defaultModel: self.customConfig.supportedModels.first ?? "custom-model",
            supportedModels: self.customConfig.supportedModels,
            customHeaders: self.customConfig.headers
        )
        
        self.httpService = BaseHTTPService(
            configuration: providerConfig,
            requestTransformer: CustomRequestTransformer(config: self.customConfig),
            responseParser: CustomResponseParser(config: self.customConfig)
        )
        
        super.init(configuration: config, memoryManager: memoryManager)
    }
    
    override func sendMessage(_ message: String, model: String?) async throws -> String {
        let selectedModel = model ?? agentConfiguration?.model ?? customConfig.supportedModels.first ?? "custom-model"
        
        let unifiedRequest = UnifiedChatRequest(
            model: selectedModel,
            messages: [ChatMessage(role: "user", content: message)],
            parameters: RequestParameters(
                temperature: agentConfiguration?.parameters.temperature,
                maxTokens: agentConfiguration?.parameters.maxTokens,
                topP: nil
            )
        )
        
        let response = try await httpService.sendUnifiedRequest(unifiedRequest)
        
        if let agentId = agentConfiguration?.id {
            let context = ConversationContext(chatId: UUID(), agentId: agentId)
            try await saveConversationContext(context)
        }
        
        return response.content
    }
    
    override func validateConfiguration() async throws {
        guard !customConfig.baseURL.isEmpty else {
            throw AgentServiceError.invalidConfiguration("Custom provider base URL is required")
        }
        
        guard !customConfig.supportedModels.isEmpty else {
            throw AgentServiceError.invalidConfiguration("Custom provider must support at least one model")
        }
        
        try await super.validateConfiguration()
    }
    
    // MARK: - Custom provider methods
    func updateCustomConfig(_ newConfig: CustomProviderConfig) {
        // This would require reinitializing the HTTP service
        // For now, we'll just store the config
    }
    
    func getCustomConfig() -> CustomProviderConfig {
        return customConfig
    }
    
    func testConnection() async throws -> Bool {
        // Implement a simple test to verify the custom provider is accessible
        let testMessage = "Hello"
        
        do {
            _ = try await sendMessage(testMessage, model: nil)
            return true
        } catch {
            throw AgentServiceError.networkError(NSError(domain: "CustomProviderError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to connect to custom provider: \(error.localizedDescription)"]))
        }
    }
    
    func getModelInfo() -> [String: Any] {
        return [
            "provider": providerName,
            "supportedModels": supportedModels,
            "defaultModel": customConfig.supportedModels.first ?? "custom-model",
            "capabilities": capabilities.map { $0.rawValue },
            "baseURL": customConfig.baseURL,
            "requestFormat": customConfig.requestFormat.rawValue,
            "responseFormat": customConfig.responseFormat.rawValue,
            "apiKeyConfigured": customConfig.apiKey != nil
        ]
    }
}