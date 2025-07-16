//
//  ChatEntity+CoreDataProperties.swift
//  AgentChat
//
//  Created by Mario Moschetta on 04/07/25.
//

import Foundation
import CoreData

extension ChatEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ChatEntity> {
        return NSFetchRequest<ChatEntity>(entityName: "ChatEntity")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var agentTypeString: String?
    @NSManaged public var providerJSON: String?
    @NSManaged public var selectedModel: String?
    @NSManaged public var n8nWorkflowJSON: String?
    @NSManaged public var agentConfigurationJSON: String?
    @NSManaged public var messages: NSSet?

}

// MARK: Generated accessors for messages
extension ChatEntity {

    @objc(addMessagesObject:)
    @NSManaged public func addToMessages(_ value: MessageEntity)

    @objc(removeMessagesObject:)
    @NSManaged public func removeFromMessages(_ value: MessageEntity)

    @objc(addMessages:)
    @NSManaged public func addToMessages(_ values: NSSet)

    @objc(removeMessages:)
    @NSManaged public func removeFromMessages(_ values: NSSet)

}

extension ChatEntity : Identifiable {

}