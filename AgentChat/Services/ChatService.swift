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
    
    private init() {}
    
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
    }
    
    func createNewChat(with agentConfiguration: AgentConfiguration) {
        let newChat = Chat(agentConfiguration: agentConfiguration)
        chats.append(newChat)
    }
    
    func deleteChat(at offsets: IndexSet) {
        chats.remove(atOffsets: offsets)
    }
    
    func addMessage(to chat: Chat, message: Message) {
        if let index = chats.firstIndex(where: { $0.id == chat.id }) {
            chats[index].messages.append(message)
        }
    }
    
    func getChatService(for agentType: AgentType) -> ChatServiceProtocol? {
        return serviceFactory.createChatService(for: agentType)
    }
    
    func getChatService(for provider: String) -> ChatServiceProtocol? {
        return serviceFactory.createChatService(for: provider)
    }
}

// MARK: - Chat Service Utilities
extension ChatManager {
    /// Restituisce tutti i servizi disponibili
    func getAllServices() -> [ChatServiceProtocol] {
        let agentTypes: [AgentType] = [.openAI, .claude, .mistral, .perplexity, .grok, .n8n, .custom, .hybridMultiAgent, .agentGroup, .productTeam]
        return agentTypes.compactMap { serviceFactory.createChatService(for: $0) }
    }
    
    /// Verifica se un provider è disponibile e configurato
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
    
    /// Restituisce i modelli supportati per un tipo di agente
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
