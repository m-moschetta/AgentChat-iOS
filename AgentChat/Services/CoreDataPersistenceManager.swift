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
        let context = container.viewContext
        let fetchRequest: NSFetchRequest<ChatEntity> = ChatEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", chat.id as CVarArg)

        do {
            let results = try context.fetch(fetchRequest)
            let chatEntity = results.first ?? ChatEntity(context: context)
            
            updateChatEntity(chatEntity, from: chat, in: context)
            
            saveContext()
        } catch {
            print("Failed to save or update chat: \(error)")
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
        entity.id = chat.id
        entity.agentTypeString = chat.agentType.rawValue
        
        let encoder = JSONEncoder()
        
        if let provider = chat.provider {
            entity.providerJSON = String(data: (try? encoder.encode(provider)) ?? Data(), encoding: String.Encoding.utf8)
        }
        entity.selectedModel = chat.selectedModel
        if let workflow = chat.n8nWorkflow {
            entity.n8nWorkflowJSON = String(data: (try? encoder.encode(workflow)) ?? Data(), encoding: String.Encoding.utf8)
        }
        if let config = chat.agentConfiguration {
            entity.agentConfigurationJSON = String(data: (try? encoder.encode(config)) ?? Data(), encoding: String.Encoding.utf8)
        }
        
        // Update messages
        let existingMessages = entity.messages as? Set<MessageEntity> ?? []
        let messageEntities = chat.messages.map { message -> MessageEntity in
            let messageEntity = existingMessages.first { $0.id == message.id } ?? MessageEntity(context: context)
            updateMessageEntity(messageEntity, from: message)
            messageEntity.chat = entity
            return messageEntity
        }
        entity.messages = NSSet(array: messageEntities)
    }

    private func updateMessageEntity(_ entity: MessageEntity, from message: Message) {
        entity.id = message.id
        entity.roleString = message.isUser ? "user" : "assistant"
        entity.content = message.content
        entity.timestamp = message.timestamp
    }

    private func convertToChat(from entity: ChatEntity) -> Chat {
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
    }

    private func convertToMessage(from entity: MessageEntity) -> Message {
        return Message(
            id: entity.id ?? UUID(),
            content: entity.content ?? "",
            isUser: entity.roleString == "user",
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
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
}