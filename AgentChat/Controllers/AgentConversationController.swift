//
//  AgentConversationController.swift
//  AgentChat
//
//  Created by Codex on 2025.
//

import Foundation

/// Controller that orchestrates an automatic conversation between the agents of a chat.
@MainActor
class AgentConversationController: ObservableObject {
    @ObservedObject var chat: Chat
    private var currentIndex: Int = 0

    init(chat: Chat) {
        self.chat = chat
    }

    /// Starts an automatic multi agent conversation for the given number of turns.
    func startConversation(initialPrompt: String, turns: Int) async {
        guard !chat.agents.isEmpty else { return }
        var message = initialPrompt

        for _ in 0..<turns {
            let agent = chat.agents[currentIndex]
            do {
                let reply = try await UniversalAssistantService.shared.sendMessage(
                    message,
                    agentType: agent.agentType,
                    model: agent.model
                )
                let newMessage = Message(content: reply, isUser: false, timestamp: Date(), agent: agent)
                chat.messages.append(newMessage)
                message = reply
                currentIndex = (currentIndex + 1) % chat.agents.count
            } catch {
                print("Agent conversation error: \(error)")
                break
            }
        }
    }
}
