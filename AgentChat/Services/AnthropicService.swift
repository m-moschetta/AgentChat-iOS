//
//  AnthropicService.swift
//  AgentChat
//
//  Created by Mario Moschetta on 04/07/25.
//

import Foundation

class AnthropicService: ChatServiceProtocol {
    static let shared = AnthropicService()
    private let session = URLSession.shared
    
    private init() {}
    
    var supportedModels: [String] {
        return ["claude-opus-4-20250514", "claude-sonnet-4-20250514", "claude-3-7-sonnet-20250219", "claude-3-5-sonnet-20241022", "claude-3-5-haiku-20241022", "claude-3-opus-20240229", "claude-3-haiku-20240307"]
    }
    
    var providerName: String {
        return "Anthropic"
    }
    
    func sendMessage(_ message: String, model: String?) async throws -> String {
        let selectedModel = model ?? "claude-3-5-sonnet-20241022"
        
        guard supportedModels.contains(selectedModel) else {
            throw ChatServiceError.unsupportedModel(selectedModel)
        }
        
        return try await sendMessageToAnthropic(message: message, model: selectedModel)
    }
    
    func validateConfiguration() async throws -> Bool {
        guard ConfigurationManager.shared.hasAPIKey(for: .claude) else {
            throw ChatServiceError.missingAPIKey(providerName)
        }
        return true
    }
    
    private func sendMessageToAnthropic(message: String, model: String) async throws -> String {
        guard let apiKey = ConfigurationManager.shared.getAPIKey(for: .claude) else {
            throw ChatServiceError.missingAPIKey(providerName)
        }
        
        let request = AnthropicRequest(
            model: model,
            messages: [AnthropicMessage(role: "user", content: message)],
            maxTokens: 4000,
            temperature: 0.7,
            system: nil
        )
        
        guard let url = URL(string: "https://api.anthropic.com/v1/messages") else {
            throw ChatServiceError.invalidConfiguration
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        urlRequest.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        
        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
        } catch {
            throw ChatServiceError.invalidConfiguration
        }
        
        do {
            let (data, response) = try await session.data(for: urlRequest)
            
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
            
            let anthropicResponse = try JSONDecoder().decode(AnthropicResponse.self, from: data)
            return anthropicResponse.content.first?.text ?? "Nessuna risposta ricevuta"
        } catch let error as ChatServiceError {
            throw error
        } catch {
            throw ChatServiceError.networkError(error)
        }
    }
}