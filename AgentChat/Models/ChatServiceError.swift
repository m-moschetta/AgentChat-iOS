//
//  ChatServiceError.swift
//  AgentChat
//
//  Created by Mario Moschetta on 04/07/25.
//

import Foundation

// MARK: - Chat Service Error
enum ChatServiceError: LocalizedError {
    case missingAPIKey(String)
    case invalidConfiguration
    case networkError(Error)
    case invalidResponse
    case unsupportedModel(String)
    case rateLimitExceeded
    case authenticationFailed
    case serverError(String)
    case invalidSessionId
    case configurationNotFound
    case invalidMessage(String)
    case invalidChat(String)
    case chatNotFound(String)
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKey(let provider):
            return "API key mancante per \(provider)"
        case .invalidConfiguration:
            return "Configurazione non valida"
        case .networkError(let error):
            return "Errore di rete: \(error.localizedDescription)"
        case .invalidResponse:
            return "Risposta non valida dal server"
        case .unsupportedModel(let model):
            return "Modello non supportato: \(model)"
        case .rateLimitExceeded:
            return "Limite di richieste superato"
        case .authenticationFailed:
            return "Autenticazione fallita"
        case .serverError(let message):
            return "Errore del server: \(message)"
        case .invalidSessionId:
            return "ID sessione non valido"
        case .configurationNotFound:
            return "Configurazione non trovata"
        case .invalidMessage(let message):
            return "Messaggio non valido: \(message)"
        case .invalidChat(let message):
            return "Chat non valida: \(message)"
        case .chatNotFound(let message):
            return "Chat non trovata: \(message)"
        }
    }
}