//
//  Message.swift
//  AgentChat
//
//  Created by Mario Moschetta on 04/07/25.
//

import Foundation

// MARK: - Message
struct Message: Identifiable, Equatable {
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
}