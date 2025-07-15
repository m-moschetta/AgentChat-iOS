//
//  GrokService.swift
//  AgentChat
//
//  Created by Mario Moschetta on 04/07/25.
//

import Foundation

class GrokService: ChatServiceProtocol {
    static let shared = GrokService()
    private let session = URLSession.shared
    
    private init() {}
    
    var supportedModels: [String] {
        return ["grok-4", "grok-3", "grok-3-mini", "grok-2-latest"]
    }
    
    var providerName: String {
        return "Grok"
    }
    
    func sendMessage(_ message: String, model: String?) async throws -> String {
        let selectedModel = model ?? "grok-4"
        
        guard supportedModels.contains(selectedModel) else {
            throw ChatServiceError.unsupportedModel(selectedModel)
        }
        
        return try await sendMessageToGrok(message: message, model: selectedModel)
    }
    
    func validateConfiguration() async throws -> Bool {
        guard ConfigurationManager.shared.hasAPIKey(for: .grok) else {
            throw ChatServiceError.missingAPIKey(providerName)
        }
        return true
    }
    
    private func sendMessageToGrok(message: String, model: String) async throws -> String {
        guard let apiKey = ConfigurationManager.shared.getAPIKey(for: .grok) else {
            throw ChatServiceError.missingAPIKey(providerName)
        }
        
        let request = GrokRequest(
            model: model,
            messages: [GrokMessage(role: "user", content: message)],
            temperature: nil,
            maxTokens: nil,
            topP: nil,
            stream: false
        )
        
        guard let url = URL(string: "https://api.x.ai/v1/chat/completions") else {
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
            
            let grokResponse = try JSONDecoder().decode(GrokResponse.self, from: data)
            return grokResponse.choices.first?.message.content ?? "Nessuna risposta ricevuta"
        } catch let error as ChatServiceError {
            throw error
        } catch {
            throw ChatServiceError.networkError(error)
        }
    }
}