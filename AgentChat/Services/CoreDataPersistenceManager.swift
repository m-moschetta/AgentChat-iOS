import CoreData

private func updateMessageEntity(_ entity: MessageEntity, from message: Message, in context: NSManagedObjectContext) {
    entity.id = message.id
    entity.content = message.content
    entity.timestamp = message.timestamp
    entity.isUser = message.isUser
    // If you have other attributes (e.g. isAwaitingResponse), add them here
}

private func updateChatEntity(_ entity: ChatEntity, from chat: Chat, in context: NSManagedObjectContext) {
    print("[DEBUG] Updating ChatEntity with ID: \(chat.id)")
    print("[DEBUG] Chat messages count: \((entity.messages as? Set<MessageEntity> ?? []).count)")

    entity.id = chat.id
    entity.title = chat.title
    entity.createdAt = chat.createdAt

    // Remove messages not present in chat
    let currentMessages = entity.messages as? Set<MessageEntity> ?? []
    let chatMessageIDs = Set(chat.messages.map { $0.id })
    for messageEntity in currentMessages {
        guard let entityID = messageEntity.id else { continue }
        if !chatMessageIDs.contains(entityID) {
            context.delete(messageEntity)
        }
    }

    // Add or update messages
    for message in chat.messages {
        if let messageEntity = currentMessages.first(where: { $0.id == message.id }) {
            updateMessageEntity(messageEntity, from: message, in: context)
        } else {
            let newMessageEntity = MessageEntity(context: context)
            updateMessageEntity(newMessageEntity, from: message, in: context)
            newMessageEntity.chat = entity
        }
    }

    print("[DEBUG] Updated Chat messages count: \((entity.messages as? Set<MessageEntity> ?? []).count)")
}
