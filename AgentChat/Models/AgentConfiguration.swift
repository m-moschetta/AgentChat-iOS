//
//  AgentConfiguration.swift
//  AgentChat
//
//  Created by Mario Moschetta on 04/07/25.
//

import Foundation
import SwiftUI

// MARK: - Agent Configuration
struct AgentConfiguration: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var systemPrompt: String
    var personality: String
    var role: String
    var icon: String
    var preferredProvider: String
    var temperature: Double
    var maxTokens: Int
    var isActive: Bool
    var memoryEnabled: Bool
    var contextWindow: Int // Numero di messaggi da ricordare
    
    init(
        id: UUID = UUID(),
        name: String,
        systemPrompt: String,
        personality: String,
        role: String,
        icon: String,
        preferredProvider: String,
        temperature: Double = 0.7,
        maxTokens: Int = 2000,
        isActive: Bool = true,
        memoryEnabled: Bool = true,
        contextWindow: Int = 10
    ) {
        self.id = id
        self.name = name
        self.systemPrompt = systemPrompt
        self.personality = personality
        self.role = role
        self.icon = icon
        self.preferredProvider = preferredProvider
        self.temperature = temperature
        self.maxTokens = maxTokens
        self.isActive = isActive
        self.memoryEnabled = memoryEnabled
        self.contextWindow = contextWindow
    }
    
    // MARK: - Default Agents
    static let defaultAgents: [AgentConfiguration] = [
        AgentConfiguration(
            name: "Assistente Generale",
            systemPrompt: "Sei un assistente AI utile e cordiale. Rispondi sempre in modo chiaro e preciso. Mantieni un tono professionale ma amichevole.",
            personality: "Cordiale, professionale, preciso",
            role: "Assistente Generale",
            icon: "🤖",
            preferredProvider: "OpenAI",
            temperature: 0.7,
            maxTokens: 2000,
            isActive: true,
            memoryEnabled: true,
            contextWindow: 10
        ),
        AgentConfiguration(
            name: "Esperto di Codice",
            systemPrompt: "Sei un esperto programmatore senior con anni di esperienza. Fornisci sempre codice pulito, ben commentato e seguendo le best practices. Spiega il tuo ragionamento e suggerisci miglioramenti quando possibile.",
            personality: "Tecnico, preciso, orientato alle soluzioni",
            role: "Sviluppatore Senior",
            icon: "👨‍💻",
            preferredProvider: "OpenAI",
            temperature: 0.3,
            maxTokens: 4000,
            isActive: true,
            memoryEnabled: true,
            contextWindow: 15
        ),
        AgentConfiguration(
            name: "Creativo",
            systemPrompt: "Sei un direttore creativo innovativo con una vasta esperienza nel design e nel marketing. Pensa fuori dagli schemi e proponi sempre idee originali e creative. Non aver paura di essere audace nelle tue proposte.",
            personality: "Creativo, visionario, innovativo",
            role: "Direttore Creativo",
            icon: "🎨",
            preferredProvider: "Claude",
            temperature: 0.9,
            maxTokens: 3000,
            isActive: true,
            memoryEnabled: true,
            contextWindow: 8
        ),
        AgentConfiguration(
            name: "Analista Business",
            systemPrompt: "Sei un analista business esperto con forte background in strategia aziendale. Fornisci analisi dettagliate, considera sempre il ROI e l'impatto sul business. Usa dati concreti quando possibile.",
            personality: "Analitico, strategico, orientato ai risultati",
            role: "Business Analyst",
            icon: "📊",
            preferredProvider: "OpenAI",
            temperature: 0.4,
            maxTokens: 3000,
            isActive: true,
            memoryEnabled: true,
            contextWindow: 12
        ),
        AgentConfiguration(
            name: "Tutor Educativo",
            systemPrompt: "Sei un tutor educativo paziente e competente. Spiega concetti complessi in modo semplice e comprensibile. Adatta il tuo linguaggio al livello dell'utente e fornisci esempi pratici.",
            personality: "Paziente, didattico, incoraggiante",
            role: "Tutor",
            icon: "👨‍🏫",
            preferredProvider: "Claude",
            temperature: 0.6,
            maxTokens: 2500,
            isActive: true,
            memoryEnabled: true,
            contextWindow: 10
        )
    ]
    
    // MARK: - Helper Methods
    var agentType: AgentType? {
        return AgentType(rawValue: preferredProvider)
    }
    
    var displayName: String {
        return "\(icon) \(name)"
    }
    
    func buildContextualPrompt(userMessage: String, conversationHistory: [Message] = []) -> String {
        var prompt = systemPrompt + "\n\n"
        
        // Aggiungi contesto della conversazione se disponibile
        if !conversationHistory.isEmpty && memoryEnabled {
            let recentMessages = conversationHistory.suffix(contextWindow)
            if !recentMessages.isEmpty {
                prompt += "Contesto conversazione precedente:\n"
                for message in recentMessages {
                    let sender = message.isUser ? "User" : "Assistant"
                    prompt += "\(sender): \(message.content)\n"
                }
                prompt += "\n"
            }
        }
        
        prompt += "User: \(userMessage)\nAssistant:"
        
        return prompt
    }
}

// MARK: - Agent Configuration Extensions
extension AgentConfiguration {
    static func createCustomAgent(
        name: String,
        systemPrompt: String,
        role: String,
        icon: String = "🤖",
        provider: String = "OpenAI"
    ) -> AgentConfiguration {
        return AgentConfiguration(
            name: name,
            systemPrompt: systemPrompt,
            personality: "Personalizzato",
            role: role,
            icon: icon,
            preferredProvider: provider
        )
    }
}