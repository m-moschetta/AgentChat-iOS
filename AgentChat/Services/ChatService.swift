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
    private let agentOrchestrator = AgentOrchestrator.shared
    private let persistenceManager = CoreDataPersistenceManager()
    
    // SOLUZIONE: Thread safety per operazioni concorrenti
    private let chatQueue = DispatchQueue(label: "com.agentchat.chatmanager", attributes: .concurrent)
    private let syncQueue = DispatchQueue(label: "com.agentchat.sync", qos: .userInitiated)
    
    private init() {
        // Carica le chat salvate (RIMOSSA clearAllData() che cancellava tutto)
        loadChatsFromPersistence()
    }
    
    // SOLUZIONE: Metodo thread-safe per caricare chat
    private func loadChatsFromPersistence() {
        syncQueue.async { [weak self] in
            guard let self = self else { return }
            let loadedChats = self.persistenceManager.loadChats()
            
            DispatchQueue.main.async {
                self.chats = loadedChats
            }
        }
    }
    
    /// Cancella tutti i dati (solo per debug o reset manuale)
    //    func clearAllData() {
//        persistenceManager.clearAllData()
//        chats = []
//    }
    
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
            case .deepSeek:
                return .deepSeek
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
            n8nWorkflow: workflow,
            memoryManager: AgentMemoryManager.shared
        )
        
        // SOLUZIONE: Thread-safe chat creation
        chatQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.chats.append(newChat)
            }
            
            // Salva in background
            self.syncQueue.async {
                self.persistenceManager.saveOrUpdateChat(chat: newChat)
            }
        }
    }
    
    /// Crea una nuova chat basata su una configurazione di agente personalizzata.
    func createNewChat(with agentConfiguration: AgentConfiguration) {
        let newChat = Chat(agentType: agentConfiguration.agentType, agentConfiguration: agentConfiguration, memoryManager: AgentMemoryManager.shared)
        
        // SOLUZIONE: Thread-safe chat creation
        chatQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.chats.append(newChat)
            }
            
            // Salva in background
            self.syncQueue.async {
                self.persistenceManager.saveOrUpdateChat(chat: newChat)
            }
        }
    }

    /// Crea una nuova chat di gruppo a partire da un template di gruppo di agenti.
    func createNewGroupChat(from template: AgentGroupTemplate) {
        let newChat = Chat(
            agentType: .group,
            chatType: .group,
            title: template.name,
            groupTemplate: template,
            memoryManager: AgentMemoryManager.shared
        )
        
        // SOLUZIONE: Thread-safe chat creation
        chatQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.chats.append(newChat)
            }
            
            // Salva in background
            self.syncQueue.async {
                self.persistenceManager.saveOrUpdateChat(chat: newChat)
            }
        }
    }
    
    /// Elimina una o più chat in base ai loro indici.
    func deleteChat(at offsets: IndexSet) {
        let idsToDelete = offsets.map { chats[$0].id }
        
        // SOLUZIONE: Thread-safe chat deletion
        chatQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            // Elimina dal persistence in background
            self.syncQueue.async {
                for id in idsToDelete {
                    self.persistenceManager.deleteChat(with: id)
                }
            }
            
            // Aggiorna UI sul main thread
            DispatchQueue.main.async {
                self.chats.remove(atOffsets: offsets)
            }
        }
    }

    /// Aggiunge un nuovo messaggio a una chat esistente.
    func addMessage(to chat: Chat, message: Message) throws {
        // Validazione dati pre-salvataggio
        guard !message.content.isEmpty else {
            print("[ERROR] Message content cannot be empty")
            throw ChatServiceError.invalidMessage("Message content cannot be empty")
        }
        
        guard chat.id != UUID(uuidString: "00000000-0000-0000-0000-000000000000") else {
            print("[ERROR] Chat must have a valid ID")
            throw ChatServiceError.invalidChat("Chat must have a valid ID")
        }
        
        guard let index = chats.firstIndex(where: { $0.id == chat.id }) else {
            print("[ERROR] Chat with ID \(chat.id) not found in chats array")
            throw ChatServiceError.chatNotFound("Chat with ID \(chat.id) not found")
        }

        print("--- Inizio addMessage (thread-safe) per chat ID: \(chat.id) ---")
        print("Messaggio da aggiungere: \(message.content) (Role: \(message.isUser ? "user" : "assistant"))")
        print("Numero messaggi prima dell'aggiunta: \(chats[index].messages.count)")

        // SOLUZIONE: Thread-safe message addition
        chatQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            // Aggiorna UI sul main thread
            DispatchQueue.main.async {
                if let currentIndex = self.chats.firstIndex(where: { $0.id == chat.id }) {
                    self.chats[currentIndex].messages.append(message)
                    self.chats[currentIndex].updateLastActivity()
                    
                    print("Numero messaggi dopo l'aggiunta: \(self.chats[currentIndex].messages.count)")
                    
                    // Salva in background
                    let updatedChat = self.chats[currentIndex]
                    self.syncQueue.async {
                        self.persistenceManager.saveOrUpdateChat(chat: updatedChat)
                        print("--- Fine addMessage per chat ID: \(chat.id) ---")
                    }
                }
            }
        }
    }
    
    /// Salva una chat aggiornata nel persistence manager
    func saveChat(_ chat: Chat) {
        // SOLUZIONE: Thread-safe save operation
        syncQueue.async { [weak self] in
            guard let self = self else { return }
            self.persistenceManager.saveOrUpdateChat(chat: chat)
        }
    }

    // MARK: - Import/Export
    
    // MARK: - Import/Export (Refactoring Needed)

    /// Esporta tutte le chat in un file e restituisce l'URL del file.
    func exportChats() -> URL? {
        // TODO: Implementare l'esportazione da Core Data
        return nil
    }

    /// Importa le chat da un file JSON e sovrascrive quelle correnti.
    func importChats(from url: URL) {
        // TODO: Implementare l'importazione in Core Data
    }
    
    /// Restituisce l'istanza del servizio di chat per un dato tipo di agente (legacy).
    func getChatService(for agentType: AgentType) -> ChatServiceProtocol? {
        return serviceFactory.createChatService(for: agentType)
    }
    
    /// Restituisce l'istanza del servizio di chat per un dato provider (identificato da una stringa) (legacy).
    func getChatService(for provider: String) -> ChatServiceProtocol? {
        return serviceFactory.createChatService(for: provider)
    }
    
    /// Restituisce l'istanza del servizio agente per una configurazione specifica.
    func getAgentService(for configuration: AgentConfiguration) -> AgentServiceProtocol? {
        return serviceFactory.createAgentService(for: configuration)
    }
    
    /// Restituisce l'istanza del servizio agente per un tipo di agente.
    func getAgentService(for agentType: AgentType, configuration: AgentConfiguration? = nil) -> AgentServiceProtocol? {
        return serviceFactory.createAgentService(for: agentType, configuration: configuration)
    }
    
    /// Restituisce l'orchestratore degli agenti.
    func getAgentOrchestrator() -> AgentOrchestrator {
        return agentOrchestrator
    }
}

// MARK: - Chat Service Utilities
extension ChatManager {
    /// Restituisce tutti i servizi disponibili.
    func getAllServices() -> [ChatServiceProtocol] {
        let agentTypes: [AgentType] = [.openAI, .claude, .mistral, .perplexity, .grok, .n8n, .custom, .hybridMultiAgent, .agentGroup, .productTeam]
        return agentTypes.compactMap { serviceFactory.createChatService(for: $0) }
    }
    
    /// Verifica se un provider è disponibile e configurato correttamente (legacy).
    func isProviderAvailable(_ agentType: AgentType) async -> Bool {
        guard let service = serviceFactory.createChatService(for: agentType) else {
            return false
        }
        
        do {
            try await service.validateConfiguration()
            return true
        } catch {
            return false
        }
    }
    
    /// Verifica se un agente è disponibile e configurato correttamente.
    func isAgentAvailable(_ configuration: AgentConfiguration) async -> Bool {
        guard let service = serviceFactory.createAgentService(for: configuration) else {
            return false
        }
        
        do {
            try await service.validateConfiguration()
            return true
        } catch {
            return false
        }
    }
    
    /// Restituisce i modelli supportati per un tipo di agente (legacy).
    func getSupportedModels(for agentType: AgentType) -> [String] {
        guard let service = serviceFactory.createChatService(for: agentType) else {
            return []
        }
        return service.supportedModels
    }
    
    /// Restituisce i modelli supportati per una configurazione di agente.
    func getSupportedModels(for configuration: AgentConfiguration) -> [String] {
        guard let service = serviceFactory.createAgentService(for: configuration) else {
            return []
        }
        return service.supportedModels
    }
    
    // MARK: - Agent Session Management
    
    /// Crea una nuova sessione di agente singolo.
    func createSingleAgentSession(with configuration: AgentConfiguration) -> String? {
        do {
            let chatId = UUID()
            let session = try agentOrchestrator.createSession(for: configuration.id, chatId: chatId, sessionType: .single)
            return session.id.uuidString
        } catch {
            return nil
        }
    }
    
    /// Crea una nuova sessione multi-agente.
    func createMultiAgentSession(with configurations: [AgentConfiguration], taskType: TaskType = .collaboration) -> String? {
        // Per ora creiamo una sessione con il primo agente, in futuro implementeremo il multi-agente completo
        guard let firstConfig = configurations.first else { return nil }
        do {
            let chatId = UUID()
            let session = try agentOrchestrator.createSession(for: firstConfig.id, chatId: chatId, sessionType: .group)
            return session.id.uuidString
        } catch {
            return nil
        }
    }
    
    /// Invia un messaggio a una sessione di agente.
    func sendMessageToSession(_ sessionId: String, message: String, context: [ChatMessage] = []) async throws -> String {
        guard let uuid = UUID(uuidString: sessionId) else {
            throw ChatServiceError.invalidSessionId
        }
        return try await agentOrchestrator.processMessage(message, for: uuid)
    }
    
    /// Termina una sessione di agente.
    func endAgentSession(_ sessionId: String) {
        guard let uuid = UUID(uuidString: sessionId) else { return }
        agentOrchestrator.endSession(uuid)
    }
    
    /// Ottiene lo stato di una sessione di agente.
    func getSessionStatus(_ sessionId: String) -> (isActive: Bool, type: SessionType?) {
        guard let uuid = UUID(uuidString: sessionId) else {
            return (false, nil)
        }
        if let session = agentOrchestrator.getSession(for: uuid) {
            return (true, session.sessionType)
        }
        return (false, nil)
    }
}

// MARK: - Legacy Support
// ChatServiceFactory is now defined in ChatServiceFactory.swift
// This extension provides backward compatibility through ChatManager.shared