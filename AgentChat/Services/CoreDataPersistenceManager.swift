import Foundation
import CoreData

class CoreDataPersistenceManager {
    func clearAllData() {
        let context = container.viewContext
        
        // Delete all ChatEntity objects
        let chatFetchRequest: NSFetchRequest<NSFetchRequestResult> = ChatEntity.fetchRequest()
        let chatDeleteRequest = NSBatchDeleteRequest(fetchRequest: chatFetchRequest)
        
        // Delete all MessageEntity objects
        let messageFetchRequest: NSFetchRequest<NSFetchRequestResult> = MessageEntity.fetchRequest()
        let messageDeleteRequest = NSBatchDeleteRequest(fetchRequest: messageFetchRequest)
        
        do {
            try context.execute(chatDeleteRequest)
            try context.execute(messageDeleteRequest)
            saveContext()
            print("All Core Data cleared successfully")
        } catch {
            print("Failed to clear Core Data: \(error)")
        }
    }

    // MARK: - CRUD Operations

    func saveOrUpdateChat(chat: Chat) {
        print("--- Inizio saveOrUpdateChat per chat ID: \(chat.id) ---")
        
        // SOLUZIONE: Usa background context per thread safety
        let backgroundContext = container.newBackgroundContext()
        
        backgroundContext.perform {
            let fetchRequest: NSFetchRequest<ChatEntity> = ChatEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", chat.id as CVarArg)

            do {
                let results = try backgroundContext.fetch(fetchRequest)
                let chatEntity: ChatEntity
                
                if let existingEntity = results.first {
                    chatEntity = existingEntity
                    print("ChatEntity esistente trovata per l'ID.")
                } else {
                    chatEntity = ChatEntity(context: backgroundContext)
                    chatEntity.id = chat.id
                    print("Nessuna ChatEntity esistente, ne creo una nuova.")
                }
                
                self.updateChatEntity(chatEntity, from: chat, in: backgroundContext)
                
                // Salva nel background context
                try backgroundContext.save()
                print("--- Fine saveOrUpdateChat per chat ID: \(chat.id) ---")
                
                // TODO: Aggiungere notifica se necessario
                 // DispatchQueue.main.async {
                 //     NotificationCenter.default.post(name: .chatUpdated, object: chat.id)
                 // }
                
            } catch {
                print("❌ ERRORE in saveOrUpdateChat: \(error)")
            }
        }
    }

    func loadChats() -> [Chat] {
        let context = container.viewContext
        let fetchRequest: NSFetchRequest<ChatEntity> = ChatEntity.fetchRequest()

        do {
            let chatEntities = try context.fetch(fetchRequest)
            return chatEntities.map { convertToChat(from: $0) }
        } catch {
            print("Failed to load chats: \(error)")
            return []
        }
    }

    func deleteChat(with id: UUID) {
        let context = container.viewContext
        let fetchRequest: NSFetchRequest<ChatEntity> = ChatEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)

        do {
            let results = try context.fetch(fetchRequest)
            if let chatEntity = results.first {
                context.delete(chatEntity)
                saveContext()
            }
        } catch {
            print("Failed to delete chat: \(error)")
        }
    }

    // MARK: - Private Conversion Helpers

    private func updateChatEntity(_ entity: ChatEntity, from chat: Chat, in context: NSManagedObjectContext) {
        print("[DEBUG] Updating ChatEntity with ID: \(chat.id)")
        print("[DEBUG] Chat messages count: \(chat.messages.count)")
        print("[DEBUG] Chat title: \(chat.title)")
        print("[DEBUG] Chat agentType: \(chat.agentType.rawValue)")
        print("[DEBUG] Chat chatType: \(chat.chatType.rawValue)")
        
        entity.id = chat.id
        entity.agentTypeString = chat.agentType.rawValue
        entity.chatTypeString = chat.chatType.rawValue
        entity.title = chat.title
        entity.isMemoryEnabled = chat.isMemoryEnabled
        entity.createdAt = chat.createdAt
        entity.lastActivity = chat.lastActivity
        
        let encoder = JSONEncoder()
        
        entity.selectedModel = chat.selectedModel

        if let provider = chat.provider {
            do {
                let data = try encoder.encode(provider)
                entity.providerJSON = String(data: data, encoding: .utf8)
            } catch {
                print("--- ERRORE FATALE: Impossibile codificare la proprietà 'provider' per la chat \(chat.id): \(error) ---")
            }
        }

        if let n8nWorkflow = chat.n8nWorkflow {
            do {
                let data = try encoder.encode(n8nWorkflow)
                entity.n8nWorkflowJSON = String(data: data, encoding: .utf8)
            } catch {
                print("--- ERRORE FATALE: Impossibile codificare la proprietà 'n8nWorkflow' per la chat \(chat.id): \(error) ---")
            }
        }

        // SOLUZIONE: Serializzazione sicura con fallback
        if let agentConfiguration = chat.agentConfiguration {
            do {
                let data = try encoder.encode(agentConfiguration)
                entity.agentConfigurationJSON = String(data: data, encoding: .utf8)
            } catch {
                print("⚠️ Serialization failed for agentConfiguration: \(error)")
                entity.agentConfigurationJSON = nil // Fallback sicuro
                print("Config details: name=\(agentConfiguration.name), provider=\(agentConfiguration.preferredProvider)")
            }
        } else {
            entity.agentConfigurationJSON = nil
        }

        if let groupTemplate = chat.groupTemplate {
            do {
                let data = try encoder.encode(groupTemplate)
                entity.groupTemplateJSON = String(data: data, encoding: .utf8)
            } catch {
                print("--- ERRORE FATALE: Impossibile codificare la proprietà 'groupTemplate' per la chat \(chat.id): \(error) ---")
            }
        }
        
        print("    -> Aggiornamento messaggi. Chat ha \(chat.messages.count) messaggi.")
        let existingMessageEntities = entity.messages as? Set<MessageEntity> ?? Set()
        var messageEntitiesById = Dictionary(uniqueKeysWithValues: existingMessageEntities.map { ($0.id!, $0) })

        for message in chat.messages {
            let messageEntity = messageEntitiesById[message.id] ?? MessageEntity(context: context)
            updateMessageEntity(messageEntity, from: message)
            messageEntity.chat = entity
            messageEntitiesById[message.id] = messageEntity
        }

        let newMessageEntities = NSSet(array: Array(messageEntitiesById.values))
        entity.messages = newMessageEntities
        print("    -> Messaggi aggiornati. La ChatEntity ora ha \(newMessageEntities.count) messaggi.")
        print("  -> Fine updateChatEntity per ID: \(chat.id)")
    }

    private func updateMessageEntity(_ entity: MessageEntity, from message: Message) {
        entity.id = message.id
        entity.isUser = message.isUser
        entity.content = message.content
        entity.timestamp = message.timestamp
    }

    private func convertToChat(from entity: ChatEntity) -> Chat {
        return Chat(fromEntity: entity, memoryManager: AgentMemoryManager.shared)
    }

    private func convertToMessage(from entity: MessageEntity) -> Message {
        return Message.createUnsafe(
            id: entity.id ?? UUID(),
            content: entity.content ?? "",
            isUser: entity.isUser,
            timestamp: entity.timestamp ?? Date()
        )
    }


    let container: NSPersistentContainer

    init() {
        container = NSPersistentContainer(name: "AgentChat")
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
    }

    func saveContext () {
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
                print("[DEBUG] CoreData save successful")
            } catch {
                print("[ERROR] CoreData save failed: \(error.localizedDescription)")
                if let coreDataError = error as NSError? {
                    print("[ERROR] CoreData error details: \(coreDataError.userInfo)")
                }
                // Invece di un fatalError, che chiude l'app, logghiamo l'errore
                // per poterlo ispezionare durante il debug.
                // fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        } else {
            print("[DEBUG] CoreData context has no changes to save.")
        }
    }
}