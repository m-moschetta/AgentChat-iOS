//
//  PerplexityService.swift
//  AgentChat
//
//  Created by Mario Moschetta on 04/07/25.
//

import Foundation

class PerplexityService: ChatServiceProtocol {
    static let shared = PerplexityService()
    private let session = URLSession.shared
    
    private init() {}
    
    var supportedModels: [String] {
        return ["sonar-pro", "sonar", "sonar-reasoning-pro", "sonar-reasoning", "sonar-deep-research", "sonar-large"]
    }
    
    var providerName: String {
        return "Perplexity"
    }
    
    func sendMessage(_ message: String, model: String?) async throws -> String {
        let selectedModel = model ?? "sonar-pro"
        
        guard supportedModels.contains(selectedModel) else {
            throw ChatServiceError.unsupportedModel(selectedModel)
        }
        
        return try await sendMessageToPerplexity(message: message, model: selectedModel)
    }
    
    func validateConfiguration() async throws -> Bool {
        guard KeychainService.shared.hasAPIKey(for: "perplexity") else {
            throw ChatServiceError.missingAPIKey(providerName)
        }
        return true
    }
    
    private func sendMessageToPerplexity(message: String, model: String) async throws -> String {
        guard let apiKey = KeychainService.shared.getAPIKey(for: "perplexity") else {
            throw ChatServiceError.missingAPIKey(providerName)
        }
        
        let request = PerplexityRequest(
            model: model,
            messages: [PerplexityMessage(role: "user", content: message)],
            maxTokens: 4000,
            temperature: 0.7,
            topP: nil,
            topK: nil,
            stream: false,
            presencePenalty: nil,
            frequencyPenalty: nil
        )
        
        guard let url = URL(string: "https://api.perplexity.ai/chat/completions") else {
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
            
            let perplexityResponse = try JSONDecoder().decode(PerplexityResponse.self, from: data)
            return perplexityResponse.choices.first?.message.content ?? "Nessuna risposta ricevuta"
        } catch let error as ChatServiceError {
            throw error
        } catch {
            throw ChatServiceError.networkError(error)
        }
    }
}