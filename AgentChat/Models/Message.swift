//
//  Message.swift
//  AgentChat
//
//  Created by Mario Moschetta on 04/07/25.
//

import Foundation

// MARK: - Message
struct Message: Identifiable, Equatable, Codable, Comparable {
    static func < (lhs: Message, rhs: Message) -> Bool {
        return lhs.timestamp < rhs.timestamp
    }
    let id: UUID
    let content: String
    let isUser: Bool
    let timestamp: Date
    
    init(id: UUID = UUID(), content: String, isUser: Bool, timestamp: Date = Date()) {
        self.id = id
        self.content = content
        self.isUser = isUser
        self.timestamp = timestamp
    }

    init(from entity: MessageEntity) {
        self.id = entity.id ?? UUID()
        self.content = entity.content ?? ""
        self.isUser = entity.isUser
        self.timestamp = entity.timestamp ?? Date()
    }
}