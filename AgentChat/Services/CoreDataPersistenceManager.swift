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
        let context = container.viewContext
        let fetchRequest: NSFetchRequest<ChatEntity> = ChatEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", chat.id as CVarArg)

        do {
            let results = try context.fetch(fetchRequest)
            let chatEntity = results.first ?? ChatEntity(context: context)
            if results.first != nil {
                print("ChatEntity esistente trovata per l'ID.")
            } else {
                print("Nessuna ChatEntity esistente, ne creo una nuova.")
            }
            
            updateChatEntity(chatEntity, from: chat, in: context)
            
            saveContext()
            print("--- Fine saveOrUpdateChat per chat ID: \(chat.id) ---")
        } catch {
            print("ERRORE FATALE in saveOrUpdateChat: \(error)")
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
        print("  -> Inizio updateChatEntity per ID: \(chat.id)")
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

        if let agentConfiguration = chat.agentConfiguration {
            do {
                let data = try encoder.encode(agentConfiguration)
                entity.agentConfigurationJSON = String(data: data, encoding: .utf8)
            } catch {
                print("--- ERRORE FATALE: Impossibile codificare la proprietà 'agentConfiguration' per la chat \(chat.id): \(error) ---")
            }
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
<<<<<<< Updated upstream
        let decoder = JSONDecoder()
        
        let provider = entity.providerJSON.flatMap { $0.data(using: String.Encoding.utf8) }.flatMap {
            try? decoder.decode(AssistantProvider.self, from: $0)
        }
        let n8nWorkflow = entity.n8nWorkflowJSON.flatMap { $0.data(using: String.Encoding.utf8) }.flatMap {
            try? decoder.decode(N8NWorkflow.self, from: $0)
        }
        let agentConfig = entity.agentConfigurationJSON.flatMap { $0.data(using: String.Encoding.utf8) }.flatMap {
            try? decoder.decode(AgentConfiguration.self, from: $0)
        }

        var chat = Chat(
            id: entity.id ?? UUID(),
            agentType: AgentType(rawValue: entity.agentTypeString ?? "") ?? .openAI,
            provider: provider,
            selectedModel: entity.selectedModel,
            n8nWorkflow: n8nWorkflow
        )
        
        // Set agent configuration separately
        chat.agentConfiguration = agentConfig

        if let messageEntities = entity.messages as? Set<MessageEntity> {
            chat.messages = messageEntities.map { convertToMessage(from: $0) }.sorted(by: { $0.timestamp < $1.timestamp })
        }
        
        return chat
=======
        return Chat(from: entity)
>>>>>>> Stashed changes
    }

    private func convertToMessage(from entity: MessageEntity) -> Message {
        return Message(
            id: entity.id ?? UUID(),
            content: entity.content ?? "",
<<<<<<< Updated upstream
            isUser: entity.roleString == "user",
=======
            isUser: entity.isUser,
>>>>>>> Stashed changes
            timestamp: entity.timestamp ?? Date()
        )
    }


    static let shared = CoreDataPersistenceManager()

    let container: NSPersistentContainer

    private init() {
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
<<<<<<< Updated upstream
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
=======
                print("✅ Core Data context saved successfully.")
            } catch {
                let nserror = error as NSError
                print("❌ Failed to save Core Data context: \(nserror), \(nserror.userInfo)")
                // Invece di un fatalError, che chiude l'app, logghiamo l'errore
                // per poterlo ispezionare durante il debug.
                // fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        } else {
            print("ℹ️ Core Data context has no changes to save.")
>>>>>>> Stashed changes
        }
    }
}