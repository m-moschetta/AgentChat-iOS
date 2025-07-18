//
//  BaseHTTPService.swift
//  AgentChat
//
//  Created by Mario Moschetta on 04/07/25.
//

import Foundation

// MARK: - Provider Configuration
struct ProviderConfiguration {
    let name: String
    let baseURL: String
    let authHeaderName: String
    let authHeaderPrefix: String
    let apiVersion: String?
    let defaultModel: String
    let supportedModels: [String]
    
    // Custom headers specifici del provider
    let customHeaders: [String: String]
    
    init(
        name: String,
        baseURL: String,
        authHeaderName: String = "Authorization",
        authHeaderPrefix: String = "Bearer",
        apiVersion: String? = nil,
        defaultModel: String,
        supportedModels: [String],
        customHeaders: [String: String] = [:]
    ) {
        self.name = name
        self.baseURL = baseURL
        self.authHeaderName = authHeaderName
        self.authHeaderPrefix = authHeaderPrefix
        self.apiVersion = apiVersion
        self.defaultModel = defaultModel
        self.supportedModels = supportedModels
        self.customHeaders = customHeaders
    }
}

// MARK: - Unified Request/Response Models
struct UnifiedChatRequest {
    let model: String
    let messages: [ChatMessage]
    let parameters: RequestParameters
}

struct ChatMessage {
    let role: String
    let content: String
}

struct RequestParameters {
    let temperature: Double?
    let maxTokens: Int?
    let topP: Double?
    let stream: Bool?
    let stop: [String]?
    let topK: Int?
    let safePrompt: Bool?
    let stopSequences: [String]?
    
    // Provider-specific parameters
    let customParameters: [String: String]
    
    init(
        temperature: Double? = nil,
        maxTokens: Int? = nil,
        topP: Double? = nil,
        stream: Bool? = false,
        stop: [String]? = nil,
        topK: Int? = nil,
        safePrompt: Bool? = nil,
        stopSequences: [String]? = nil,
        customParameters: [String: String] = [:]
    ) {
        self.temperature = temperature
        self.maxTokens = maxTokens
        self.topP = topP
        self.stream = stream
        self.stop = stop
        self.topK = topK
        self.safePrompt = safePrompt
        self.stopSequences = stopSequences
        self.customParameters = customParameters
    }
}

struct UnifiedChatResponse {
    let content: String
    let model: String
    let usage: TokenUsage?
}

struct TokenUsage {
    let promptTokens: Int?
    let completionTokens: Int?
    let totalTokens: Int?
}

// MARK: - Request/Response Transformers
protocol RequestTransformer {
    func transform(_ request: UnifiedChatRequest) throws -> Data
}

protocol ResponseParser {
    func parse(_ data: Data) throws -> UnifiedChatResponse
}

// MARK: - Base HTTP Service
class BaseHTTPService: ChatServiceProtocol {
    
    // MARK: - Properties
    private let session: URLSession
    private let configuration: ProviderConfiguration
    private let requestTransformer: RequestTransformer
    private let responseParser: ResponseParser
    
    // MARK: - Initialization
    init(
        configuration: ProviderConfiguration,
        requestTransformer: RequestTransformer,
        responseParser: ResponseParser,
        session: URLSession = .shared
    ) {
        self.configuration = configuration
        self.requestTransformer = requestTransformer
        self.responseParser = responseParser
        self.session = session
    }
    
    // MARK: - ChatServiceProtocol Implementation
    var supportedModels: [String] {
        return configuration.supportedModels
    }
    
    var providerName: String {
        return configuration.name
    }
    
    func sendMessage(_ message: String, configuration: AgentConfiguration) async throws -> String {
        guard supportedModels.contains(configuration.model) else {
            throw ChatServiceError.unsupportedModel(configuration.model)
        }
        
        let unifiedRequest = UnifiedChatRequest(
            model: configuration.model,
            messages: [ChatMessage(role: "user", content: message)],
            parameters: buildRequestParameters(from: configuration)
        )
        
        let response = try await sendUnifiedRequest(unifiedRequest)
        return response.content
    }
    
    func validateConfiguration() async throws {
        guard KeychainService.shared.hasAPIKey(for: getKeychainKey()) else {
            throw ChatServiceError.missingAPIKey(providerName)
        }

    }
    
    // MARK: - Protected Methods (to be overridden)
    func getKeychainKey() -> String {
        return configuration.name.lowercased()
    }
    
    func buildRequestParameters(from configuration: AgentConfiguration) -> RequestParameters {
        return RequestParameters(
            temperature: configuration.parameters.temperature,
            maxTokens: configuration.parameters.maxTokens,
            topP: configuration.parameters.topP,
            stream: false, // Stream non è ancora gestito
            stop: configuration.parameters.stopSequences, // Assuming 'stop' and 'stopSequences' are the same
            topK: nil, // topK is not a direct parameter in AgentParameters, decide how to handle it.
            safePrompt: nil, // same for safePrompt
            stopSequences: configuration.parameters.stopSequences
        )
    }
    
    // MARK: - Core HTTP Logic
    func sendUnifiedRequest(_ request: UnifiedChatRequest) async throws -> UnifiedChatResponse {
        // Validate API key
        guard let apiKey = KeychainService.shared.getAPIKey(for: getKeychainKey()) else {
            throw ChatServiceError.missingAPIKey(providerName)
        }
        
        // Create URL
        guard let url = URL(string: configuration.baseURL) else {
            throw ChatServiceError.invalidConfiguration
        }
        
        // Create URLRequest
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Set authentication header
        let authValue = configuration.authHeaderPrefix.isEmpty ? apiKey : "\(configuration.authHeaderPrefix) \(apiKey)"
        urlRequest.setValue(authValue, forHTTPHeaderField: configuration.authHeaderName)
        
        // Set API version if needed
        if let apiVersion = configuration.apiVersion {
            urlRequest.setValue(apiVersion, forHTTPHeaderField: "anthropic-version")
        }
        
        // Set custom headers
        for (key, value) in configuration.customHeaders {
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }
        
        // Transform request to provider-specific format
        do {
            urlRequest.httpBody = try requestTransformer.transform(request)
        } catch {
            throw ChatServiceError.invalidConfiguration
        }
        
        // Send request
        do {
            let (data, response) = try await session.data(for: urlRequest)
            
            // Validate HTTP response
            try validateHTTPResponse(response)
            
            // Parse response
            return try responseParser.parse(data)
            
        } catch let error as ChatServiceError {
            throw error
        } catch {
            throw ChatServiceError.networkError(error)
        }
    }
    
    // MARK: - HTTP Response Validation
    private func validateHTTPResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ChatServiceError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            break
        case 401:
            throw ChatServiceError.authenticationFailed
        case 429:
            throw ChatServiceError.rateLimitExceeded
        case 500...599:
            throw ChatServiceError.serverError("Server error: \(httpResponse.statusCode)")
        default:
            throw ChatServiceError.serverError("HTTP error: \(httpResponse.statusCode)")
        }
    }
}

// MARK: - Provider Configurations
extension ProviderConfiguration {
    static let openAI = ProviderConfiguration(
        name: "OpenAI",
        baseURL: "https://api.openai.com/v1/chat/completions",
        defaultModel: "gpt-4.1-mini",
        supportedModels: [
            // Modelli Chat più recenti (Luglio 2025)
            "gpt-4.1", "gpt-4.1-mini", "gpt-4.1-nano", 
            "gpt-4o", "gpt-4o-mini", 
            "gpt-4.5",
            "o3", "o3-pro", 
            "o4-mini", "o4-mini-high",
            "gpt-3.5-turbo",
            // Modelli Embedding
            "text-embedding-3-large", "text-embedding-3-small", "text-embedding-ada-002",
            // Modelli Specializzati
            "gpt-image-1"
        ]
    )
    
    static let anthropic = ProviderConfiguration(
        name: "Anthropic",
        baseURL: "https://api.anthropic.com/v1/messages",
        authHeaderName: "x-api-key",
        authHeaderPrefix: "",
        apiVersion: "2023-06-01",
        defaultModel: "claude-3-5-sonnet-20241022",
        supportedModels: ["claude-opus-4-20250514", "claude-sonnet-4-20250514", "claude-3-7-sonnet-20250219", "claude-3-5-sonnet-20241022", "claude-3-5-haiku-20241022", "claude-3-opus-20240229", "claude-3-haiku-20240307"]
    )
    
    static let mistral = ProviderConfiguration(
        name: "Mistral",
        baseURL: "https://api.mistral.ai/v1/chat/completions",
        defaultModel: "mistral-medium-2505",
        supportedModels: ["mistral-medium-2505", "magistral-medium-2506", "codestral-2501", "devstral-medium-2507", "mistral-large-2411", "pixtral-large-2411", "ministral-8b-2410", "ministral-3b-2410", "magistral-small-2506", "mistral-small-2506", "devstral-small-2507", "mistral-nemo-2407", "pixtral-12b-2409", "mistral-embed", "mistral-moderation-2411", "mistral-ocr-2505"]
    )
    
    static let grok = ProviderConfiguration(
        name: "Grok",
        baseURL: "https://api.x.ai/v1/chat/completions",
        defaultModel: "grok-4",
        supportedModels: [
            // Modelli Grok 4 (Luglio 2025)
            "grok-4", "grok-4-heavy",
            // Modelli Legacy
            "grok-3", "grok-beta", "grok-vision-beta"
        ]
    )
    
    static let perplexity = ProviderConfiguration(
        name: "Perplexity",
        baseURL: "https://api.perplexity.ai/chat/completions",
        defaultModel: "sonar-pro",
        supportedModels: ["sonar-reasoning-pro", "sonar-reasoning", "sonar-pro", "sonar", "sonar-deep-research", "r1-1776", "llama-3.1-sonar-large-128k-online", "llama-3.1-sonar-small-128k-online", "llama-3.1-sonar-large-128k-chat", "llama-3.1-sonar-small-128k-chat", "llama-3.1-8b-instruct", "llama-3.1-70b-instruct"]
    )
    

    
    static let deepSeek = ProviderConfiguration(
        name: "DeepSeek",
        baseURL: "https://api.deepseek.com/v1/chat/completions",
        authHeaderName: "Authorization",
        authHeaderPrefix: "Bearer",
        apiVersion: nil,
        defaultModel: "deepseek-r1-0528",
        supportedModels: [
            // Modelli R1 (Ragionamento)
            "deepseek-r1-0528", "deepseek-r1", "deepseek-r1-distill-32b", "deepseek-r1-distill-70b",
            // Modelli V3
            "deepseek-v3-0324", "deepseek-v3",
            // Modelli Specializzati
            "deepseek-coder-v2", "deepseek-math"
        ],
        customHeaders: [:]
    )
}