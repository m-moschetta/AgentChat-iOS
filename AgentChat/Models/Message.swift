//
//  Message.swift
//  AgentChat
//
//  Created by Mario Moschetta on 04/07/25.
//

import Foundation
import CoreData

// MARK: - Message Validation Errors
enum MessageValidationError: Error, LocalizedError {
    case emptyContent
    case contentTooLong(maxLength: Int)
    case invalidTimestamp
    case corruptedData(String)
    
    var errorDescription: String? {
        switch self {
        case .emptyContent:
            return "Message content cannot be empty"
        case .contentTooLong(let maxLength):
            return "Message content exceeds maximum length of \(maxLength) characters"
        case .invalidTimestamp:
            return "Message timestamp is invalid"
        case .corruptedData(let details):
            return "Message data is corrupted: \(details)"
        }
    }
}

// MARK: - Message
struct Message: Identifiable, Equatable, Codable, Comparable {
    static func < (lhs: Message, rhs: Message) -> Bool {
        return lhs.timestamp < rhs.timestamp
    }
    
    // MARK: - Constants
    static let maxContentLength = 10000
    static let minContentLength = 1
    
    // MARK: - Properties
    let id: UUID
    let content: String
    let isUser: Bool
    let timestamp: Date
    
    // MARK: - Computed Properties
    var isValid: Bool {
        return !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               content.count <= Self.maxContentLength &&
               timestamp <= Date()
    }
    
    var trimmedContent: String {
        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    var wordCount: Int {
        return trimmedContent.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }.count
    }
    
    var characterCount: Int {
        return content.count
    }
    
    // MARK: - Initializers
    init(id: UUID = UUID(), content: String, isUser: Bool, timestamp: Date = Date()) throws {
        // Validate content
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw MessageValidationError.emptyContent
        }
        
        guard content.count <= Self.maxContentLength else {
            throw MessageValidationError.contentTooLong(maxLength: Self.maxContentLength)
        }
        
        // Validate timestamp (should not be in the future)
        guard timestamp <= Date() else {
            throw MessageValidationError.invalidTimestamp
        }
        
        self.id = id
        self.content = content
        self.isUser = isUser
        self.timestamp = timestamp
    }
    
    // Private unsafe initializer
    private init(unsafeId id: UUID, unsafeContent content: String, unsafeIsUser isUser: Bool, unsafeTimestamp timestamp: Date) {
        self.id = id
        self.content = content
        self.isUser = isUser
        self.timestamp = timestamp
    }
    
    // Convenience initializer for unsafe creation (backward compatibility)
    static func createUnsafe(id: UUID = UUID(), content: String, isUser: Bool, timestamp: Date = Date()) -> Message {
        // Use private initializer that doesn't throw
        return Message(
            unsafeId: id,
            unsafeContent: content.isEmpty ? " " : content, // Prevent empty content
            unsafeIsUser: isUser,
            unsafeTimestamp: min(timestamp, Date()) // Prevent future timestamps
        )
    }

    init(from entity: MessageEntity) throws {
        guard let entityId = entity.id else {
            throw MessageValidationError.corruptedData("Missing message ID")
        }
        
        guard let entityContent = entity.content else {
            throw MessageValidationError.corruptedData("Missing message content")
        }
        
        guard let entityTimestamp = entity.timestamp else {
            throw MessageValidationError.corruptedData("Missing message timestamp")
        }
        
        try self.init(
            id: entityId,
            content: entityContent,
            isUser: entity.isUser,
            timestamp: entityTimestamp
        )
    }
    
    // Unsafe initializer for Core Data (backward compatibility)
    static func fromEntityUnsafe(_ entity: MessageEntity) -> Message {
        return Message(
            unsafeId: entity.id ?? UUID(),
            unsafeContent: entity.content ?? "",
            unsafeIsUser: entity.isUser,
            unsafeTimestamp: entity.timestamp ?? Date()
        )
    }
    
    // MARK: - Validation Methods
    func validate() throws {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw MessageValidationError.emptyContent
        }
        
        guard content.count <= Self.maxContentLength else {
            throw MessageValidationError.contentTooLong(maxLength: Self.maxContentLength)
        }
        
        guard timestamp <= Date() else {
            throw MessageValidationError.invalidTimestamp
        }
    }
}