//
//  CustomProviderService.swift
//  AgentChat
//
//  Created by Mario Moschetta on 04/07/25.
//

import Foundation

class CustomProviderService: ChatServiceProtocol {
    static let shared = CustomProviderService()
    private let session = URLSession.shared
    
    private init() {}

    var supportedModels: [String] {
        return ["custom-model"] // Default model for custom providers
    }
    
    var providerName: String {
        return "Custom Provider"
    }
    
    func sendMessage(_ message: String, model: String?) async throws -> String {
        // For now, we'll need a default provider - this should be improved
        guard let defaultProvider = getDefaultCustomProvider(),
              let config = AgentConfiguration.createAgentConfiguration(for: defaultProvider, model: model) else {
            throw ChatServiceError.invalidConfiguration
        }
        return try await sendMessage(message, configuration: config)
    }
    
    func validateConfiguration() async throws {
        // Basic validation - should be improved based on actual requirements

    }
    
    // MARK: - ChatServiceProtocol Implementation
    func sendMessage(_ message: String, configuration: AgentConfiguration) async throws -> String {
        // For custom providers, we'll need a default provider
        guard let defaultProvider = getDefaultCustomProvider() else {
            throw ChatServiceError.invalidConfiguration
        }
        return try await sendMessage(message: message, provider: defaultProvider, configuration: configuration)
    }
    
    private func getDefaultCustomProvider() -> AssistantProvider? {
        // This should be implemented based on your app's logic
        // For now, return nil to indicate no default provider
        return nil
    }
    
    func sendMessage(message: String, provider: AssistantProvider, configuration: AgentConfiguration) async throws -> String {
        // For custom providers, we'll try to use a generic OpenAI-compatible format
        guard let apiKey = KeychainService.shared.getAPIKey(for: provider.id) else {
            throw ChatServiceError.missingAPIKey("API key missing for provider: \(provider.name)")
        }
        
        let request = OpenAIRequest(
            model: configuration.model,
            messages: [OpenAIMessage(role: "user", content: message)],
            maxTokens: configuration.maxTokens,
            temperature: configuration.temperature,
            stream: false
        )
        
        var urlRequest = URLRequest(url: URL(string: provider.endpoint)!)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.httpBody = try JSONEncoder().encode(request)
        
        let (data, response) = try await session.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AgentServiceError.networkError(URLError(.badServerResponse))
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            if httpResponse.statusCode == 401 {
                throw ChatServiceError.authenticationFailed
            } else if httpResponse.statusCode == 429 {
                throw ChatServiceError.rateLimitExceeded
            } else {
                throw ChatServiceError.serverError("HTTP \(httpResponse.statusCode)")
            }
        }
        
        let customResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        return customResponse.choices.first?.message.content ?? "Nessuna risposta ricevuta"
    }
}