//
//  Agent.swift
//  AgentChat
//
//  Created by OpenAI on 04/07/25.
//

import Foundation

// MARK: - Agent Model
struct Agent: Codable, Identifiable, Equatable, Hashable {
    let id: String
    var name: String
    var provider: AssistantProvider
    var systemPrompt: String
    var avatar: String
    var isActive: Bool
    var isDefault: Bool

    init(id: String = UUID().uuidString,
         name: String,
         provider: AssistantProvider,
         systemPrompt: String = "",
         avatar: String = "🤖",
         isActive: Bool = true,
         isDefault: Bool = false) {
        self.id = id
        self.name = name
        self.provider = provider
        self.systemPrompt = systemPrompt
        self.avatar = avatar
        self.isActive = isActive
        self.isDefault = isDefault
    }

    static func == (lhs: Agent, rhs: Agent) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    /// Converte Agent in AgentConfiguration per compatibilità
    func toAgentConfiguration() -> AgentConfiguration {
        return AgentConfiguration(
            id: UUID(uuidString: self.id) ?? UUID(),
            name: self.name,
            systemPrompt: self.systemPrompt,
            personality: "Assistente AI", // Valore di default o da mappare se disponibile
            role: "Assistant", // Valore di default o da mappare se disponibile
            icon: self.avatar,
            preferredProvider: self.provider.type.rawValue,
            temperature: 0.7, // Valore di default
            maxTokens: 2048, // Valore di default
            isActive: self.isActive,
            memoryEnabled: true, // Valore di default
            contextWindow: 10, // Valore di default
            model: self.provider.defaultModel, // Usa il modello di default del provider
            capabilities: [], // Valore di default
            parameters: AgentParameters(
                temperature: 0.7,
                maxTokens: 2048
            ),
            customConfig: nil
        )
    }
}

// MARK: - Extension per compatibilità con MainTabView
extension Agent {
    /// Proprietà computata per mappare AssistantProvider.type ad AgentType
    var type: AgentType {
        return AgentType(rawValue: self.provider.type.rawValue) ?? .openAI
    }
}
