//
//  UniversalAssistantService.swift
//  AgentChat
//
//  Created by Mario Moschetta on 04/07/25.
//

import Foundation

// MARK: - Universal Assistant Service
class UniversalAssistantService {
    static let shared = UniversalAssistantService()
    
    private init() {}
    
    func sendMessage(_ message: String, agentType: AgentType, model: String?) async throws -> String {
        guard let service = ChatServiceFactory.createService(for: agentType) else {
            throw UniversalAssistantError.unsupportedProvider
        }
        
        // Valida la configurazione prima di inviare il messaggio
        do {
            _ = try await service.validateConfiguration()
        } catch {
            throw UniversalAssistantError.configurationError(error.localizedDescription)
        }
        
        return try await service.sendMessage(message, model: model)
    }
    
    /// Verifica se un provider è disponibile e configurato
    func isProviderAvailable(_ agentType: AgentType) async -> Bool {
        return await ChatServiceFactory.isProviderAvailable(agentType)
    }
    
    /// Restituisce i modelli supportati per un provider
    func getSupportedModels(for agentType: AgentType) -> [String] {
        return ChatServiceFactory.getSupportedModels(for: agentType)
    }
    
    /// Restituisce tutti i provider disponibili
    func getAvailableProviders() -> [AgentType] {
        return AgentType.allCases
    }

}

// MARK: - Universal Assistant Error
enum UniversalAssistantError: Error, LocalizedError {
    case unsupportedProvider
    case configurationError(String)
    case serviceError(ChatServiceError)
    
    var errorDescription: String? {
        switch self {
        case .unsupportedProvider:
            return "Provider non supportato"
        case .configurationError(let message):
            return "Errore di configurazione: \(message)"
        case .serviceError(let chatError):
            return chatError.localizedDescription
        }
    }
}