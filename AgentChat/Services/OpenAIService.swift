//
//  OpenAIService.swift
//  AgentChat
//
//  Created by Mario Moschetta on 04/07/25.
//

import Foundation

class OpenAIService: ChatServiceProtocol {
    static let shared = OpenAIService()
    private let session = URLSession.shared
    
    private init() {}
    
    var supportedModels: [String] {
        return ["o3", "o4-mini", "gpt-4.1", "gpt-4.1-mini", "gpt-4.1-nano", "gpt-4o", "gpt-4o-mini", "o1", "o1-mini"]
    }
    
    var providerName: String {
        return "OpenAI"
    }
    
    func sendMessage(_ message: String, model: String?) async throws -> String {
        let selectedModel = model ?? "gpt-4o"
        
        guard supportedModels.contains(selectedModel) else {
            throw ChatServiceError.unsupportedModel(selectedModel)
        }
        
        return try await sendMessageToOpenAI(message: message, model: selectedModel)
    }
    
    func validateConfiguration() async throws -> Bool {
        guard ConfigurationManager.shared.hasAPIKey(for: .openAI) else {
            throw ChatServiceError.missingAPIKey(providerName)
        }
        return true
    }
    
    private func sendMessageToOpenAI(message: String, model: String) async throws -> String {
        guard let apiKey = ConfigurationManager.shared.getAPIKey(for: .openAI) else {
            throw ChatServiceError.missingAPIKey(providerName)
        }
        
        let request = OpenAIRequest(
            model: model,
            messages: [OpenAIMessage(role: "user", content: message)],
            maxTokens: 4000,
            temperature: 0.7,
            stream: false
        )
        
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            throw ChatServiceError.invalidConfiguration
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
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
            
            let openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
            return openAIResponse.choices.first?.message.content ?? "Nessuna risposta ricevuta"
        } catch let error as ChatServiceError {
            throw error
        } catch {
            throw ChatServiceError.networkError(error)
        }
    }
}