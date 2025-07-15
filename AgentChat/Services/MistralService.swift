//
//  MistralService.swift
//  AgentChat
//
//  Created by Mario Moschetta on 04/07/25.
//

import Foundation

class MistralService: ChatServiceProtocol {
    static let shared = MistralService()
    private let session = URLSession.shared
    
    private init() {}
    
    var supportedModels: [String] {
        return ["mistral-large-latest", "mistral-medium-latest", "mistral-small-latest", "codestral-latest", "pixtral-large-latest", "ministral-8b-latest", "ministral-3b-latest"]
    }
    
    var providerName: String {
        return "Mistral"
    }
    
    func sendMessage(_ message: String, model: String?) async throws -> String {
        let selectedModel = model ?? "mistral-large-latest"
        
        guard supportedModels.contains(selectedModel) else {
            throw ChatServiceError.unsupportedModel(selectedModel)
        }
        
        return try await sendMessageToMistral(message: message, model: selectedModel)
    }
    
    func validateConfiguration() async throws -> Bool {
        guard ConfigurationManager.shared.hasAPIKey(for: .mistral) else {
            throw ChatServiceError.missingAPIKey(providerName)
        }
        return true
    }
    
    private func sendMessageToMistral(message: String, model: String) async throws -> String {
        guard let apiKey = ConfigurationManager.shared.getAPIKey(for: .mistral) else {
            throw ChatServiceError.missingAPIKey(providerName)
        }
        
        let request = MistralRequest(
            model: model,
            messages: [MistralMessage(role: "user", content: message)],
            temperature: 0.7,
            maxTokens: 4000,
            topP: nil,
            randomSeed: nil,
            stream: false
        )
        
        guard let url = URL(string: "https://api.mistral.ai/v1/chat/completions") else {
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
            
            let mistralResponse = try JSONDecoder().decode(MistralResponse.self, from: data)
            return mistralResponse.choices.first?.message.content ?? "Nessuna risposta ricevuta"
        } catch let error as ChatServiceError {
            throw error
        } catch {
            throw ChatServiceError.networkError(error)
        }
    }
}