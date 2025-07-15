//
//  ChatService.swift
//  AgentChat
//
//  Created by Mario Moschetta on 04/07/25.
//

import Foundation
import Combine
import SwiftUI

// Import the protocol and error definitions
// ChatServiceProtocol is defined in Protocols/ChatServiceProtocol.swift
// ChatServiceError is defined in Models/ChatServiceError.swift

// Import required models
// These imports are needed for the types used in this file

// MARK: - Chat Manager
class ChatManager: ObservableObject {
    static let shared = ChatManager()
    
    @Published var chats: [Chat] = []
    private let serviceFactory = ServiceFactory()
    
    private init() {
        // Carica le chat salvate all'avvio dell'applicazione
        chats = ChatPersistenceManager.shared.loadChats()
    }
    
    /// Crea una nuova chat basata su un provider e un modello specifici.
    func createNewChat(with provider: AssistantProvider, model: String?, workflow: N8NWorkflow? = nil) {
        let agentType: AgentType = {
            switch provider.type {
            case .openai:
                return .openAI
            case .anthropic:
                return .claude
            case .mistral:
                return .mistral
            case .perplexity:
                return .perplexity
            case .grok:
                return .grok
            case .n8n:
                return .n8n
            case .custom:
                return .custom
            }
        }()
        
        let newChat = Chat(
            agentType: agentType,
            provider: provider,
            selectedModel: model,
            n8nWorkflow: workflow
        )
        
        chats.append(newChat)
        ChatPersistenceManager.shared.saveChats(chats)
    }
    
    /// Crea una nuova chat basata su una configurazione di agente personalizzata.
    func createNewChat(with agentConfiguration: AgentConfiguration) {
        let newChat = Chat(agentConfiguration: agentConfiguration)
        chats.append(newChat)
        ChatPersistenceManager.shared.saveChats(chats)
    }
    
    /// Elimina una o più chat in base ai loro indici.
    func deleteChat(at offsets: IndexSet) {
        chats.remove(atOffsets: offsets)
        ChatPersistenceManager.shared.saveChats(chats)
    }

    /// Aggiunge un nuovo messaggio a una chat esistente.
    func addMessage(to chat: Chat, message: Message) {
        if let index = chats.firstIndex(where: { $0.id == chat.id }) {
            chats[index].messages.append(message)
            ChatPersistenceManager.shared.saveChats(chats)
        }
    }

    // MARK: - Import/Export
    
    /// Esporta tutte le chat in un file e restituisce l'URL del file.
    func exportChats() -> URL? {
        return ChatPersistenceManager.shared.exportChats(chats)
    }

    /// Importa le chat da un file JSON e sovrascrive quelle correnti.
    func importChats(from url: URL) {
        if let imported = ChatPersistenceManager.shared.importChats(from: url) {
            chats = imported
            ChatPersistenceManager.shared.saveChats(chats)
        }
    }
    
    /// Restituisce l'istanza del servizio di chat per un dato tipo di agente.
    func getChatService(for agentType: AgentType) -> ChatServiceProtocol? {
        return serviceFactory.createChatService(for: agentType)
    }
    
    /// Restituisce l'istanza del servizio di chat per un dato provider (identificato da una stringa).
    func getChatService(for provider: String) -> ChatServiceProtocol? {
        return serviceFactory.createChatService(for: provider)
    }
}

// MARK: - Chat Service Utilities
extension ChatManager {
    /// Restituisce tutti i servizi disponibili.
    func getAllServices() -> [ChatServiceProtocol] {
        let agentTypes: [AgentType] = [.openAI, .claude, .mistral, .perplexity, .grok, .n8n, .custom, .hybridMultiAgent, .agentGroup, .productTeam]
        return agentTypes.compactMap { serviceFactory.createChatService(for: $0) }
    }
    
    /// Verifica se un provider è disponibile e configurato correttamente.
    func isProviderAvailable(_ agentType: AgentType) async -> Bool {
        guard let service = serviceFactory.createChatService(for: agentType) else {
            return false
        }
        
        do {
            return try await service.validateConfiguration()
        } catch {
            return false
        }
    }
    
    /// Restituisce i modelli supportati per un tipo di agente.
    func getSupportedModels(for agentType: AgentType) -> [String] {
        guard let service = serviceFactory.createChatService(for: agentType) else {
            return []
        }
        return service.supportedModels
    }
}

// MARK: - Legacy Support
// ChatServiceFactory is now defined in ChatServiceFactory.swift
// This extension provides backward compatibility through ChatManager.shared