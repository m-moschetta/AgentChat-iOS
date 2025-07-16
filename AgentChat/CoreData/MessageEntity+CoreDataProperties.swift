//
//  MessageEntity+CoreDataProperties.swift
//  AgentChat
//
//  Created by Mario Moschetta on 04/07/25.
//

import Foundation
import CoreData

extension MessageEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<MessageEntity> {
        return NSFetchRequest<MessageEntity>(entityName: "MessageEntity")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var isUser: Bool
    @NSManaged public var content: String?
    @NSManaged public var timestamp: Date?
    @NSManaged public var isAwaitingResponse: Bool
    @NSManaged public var chat: ChatEntity?

}

extension MessageEntity : Identifiable {

}