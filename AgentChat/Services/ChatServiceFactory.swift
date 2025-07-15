//
//  ChatServiceFactory.swift
//  AgentChat
//
//  Created by Mario Moschetta on 04/07/25.
//

import Foundation

@available(*, deprecated, message: "Use ServiceFactory instead")
class ChatServiceFactory {
    static let shared = ChatServiceFactory()
    private let serviceFactory = ServiceFactory()
    
    private init() {}
    
    func createService(for agentType: AgentType) -> ChatServiceProtocol? {
        return serviceFactory.createChatService(for: agentType)
    }
    
    func createService(for provider: String) -> ChatServiceProtocol? {
        return serviceFactory.createChatService(for: provider)
    }
}