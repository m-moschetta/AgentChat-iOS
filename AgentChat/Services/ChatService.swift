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

// MARK: - Chat Manager
class ChatManager: ObservableObject {
    @Published var chats: [Chat] = []

    func createNewChat(with provider: AssistantProvider, model: String?, workflow: N8NWorkflow? = nil) {
        createNewChat(with: [provider], model: model, workflow: workflow)
    }

    func createNewChat(with providers: [AssistantProvider], model: String?, workflow: N8NWorkflow? = nil) {
        guard let first = providers.first else { return }
        let agentType: AgentType = {
            switch first.type {
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
            provider: first,
            agents: providers,
            selectedModel: model,
            n8nWorkflow: workflow
        )

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
}

// MARK: - Chat Service Factory
class ChatServiceFactory {
    static func createService(for agentType: AgentType) -> ChatServiceProtocol? {
        switch agentType {
        case .openAI:
            return OpenAIService.shared
        case .claude:
            return AnthropicService.shared
        case .mistral:
            return MistralService.shared
        case .perplexity:
            return PerplexityService.shared
        case .grok:
            return GrokService.shared
        case .n8n:
            return N8NService.shared
        case .custom:
            return CustomProviderService.shared
        }
    }
    
    /// Restituisce tutti i servizi disponibili
    static func getAllServices() -> [ChatServiceProtocol] {
        return [
            OpenAIService.shared,
            AnthropicService.shared,
            MistralService.shared,
            PerplexityService.shared,
            GrokService.shared,
            N8NService.shared,
            CustomProviderService.shared
        ]
    }
    
    /// Verifica se un provider è disponibile e configurato
    static func isProviderAvailable(_ agentType: AgentType) async -> Bool {
        guard let service = createService(for: agentType) else {
            return false
        }
        
        do {
            return try await service.validateConfiguration()
        } catch {
            return false
        }
    }
    
    /// Restituisce i modelli supportati per un tipo di agente
    static func getSupportedModels(for agentType: AgentType) -> [String] {
        guard let service = createService(for: agentType) else {
            return []
        }
        return service.supportedModels
    }
}
