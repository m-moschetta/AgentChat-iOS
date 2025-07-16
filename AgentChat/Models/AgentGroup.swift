//
//  AgentGroup.swift
//  AgentChat
//
//  Created by Mario Moschetta on 04/07/25.
//

import Foundation
import Combine

// MARK: - AgentGroup
class AgentGroup: ObservableObject, Identifiable, Codable {
    let id = UUID()
    let name: String
    let description: String
    let icon: String
    let agentType: AgentType
    
    @Published var participants: [GroupAgent]
    @Published var messages: [GroupMessage] = []
    @Published var isActive: Bool = false
    @Published var currentSpeaker: GroupAgent?
    
    private let conversationEngine = GroupConversationEngine()
    
    init(name: String, description: String, icon: String, participants: [GroupAgent], agentType: AgentType) {
        self.name = name
        self.description = description
        self.icon = icon
        self.participants = participants
        self.agentType = agentType
    }
    
    // MARK: - Codable Implementation
    private enum CodingKeys: String, CodingKey {
        case name, description, icon, participants, agentType
        // id, messages, isActive, currentSpeaker are excluded from coding
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        self.description = try container.decode(String.self, forKey: .description)
        self.icon = try container.decode(String.self, forKey: .icon)
        self.participants = try container.decode([GroupAgent].self, forKey: .participants)
        self.agentType = try container.decode(AgentType.self, forKey: .agentType)
        // Published properties are initialized with default values
        self.messages = []
        self.isActive = false
        self.currentSpeaker = nil
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
        try container.encode(icon, forKey: .icon)
        try container.encode(participants, forKey: .participants)
        try container.encode(agentType, forKey: .agentType)
    }
    
    // MARK: - Conversation Management
    func startGroupConversation(with prompt: String) async {
        await MainActor.run {
            isActive = true
            currentSpeaker = nil
        }
        
        // Messaggio iniziale dell'utente
        let userMessage = GroupMessage(
            content: prompt,
            sender: .user,
            timestamp: Date()
        )
        
        await addMessage(userMessage)
        
        // Avvia conversazione orchestrata
        await conversationEngine.orchestrateGroupDiscussion(
            initialPrompt: prompt,
            participants: participants,
            messageHandler: addMessage,
            speakerUpdateHandler: { [weak self] speaker in
                await MainActor.run {
                    self?.currentSpeaker = speaker
                }
            }
        )
        
        await MainActor.run {
            isActive = false
            currentSpeaker = nil
        }
    }
    
    @MainActor
    func addMessage(_ message: GroupMessage) {
        messages.append(message)
    }
    
    // MARK: - Utility Methods
    func clearMessages() {
        messages.removeAll()
    }
    
    func getLastMessages(count: Int) -> [GroupMessage] {
        return Array(messages.suffix(count))
    }
}

// MARK: - GroupMessage
struct GroupMessage: Identifiable {
    let id = UUID()
    let content: String
    let sender: MessageSender
    let timestamp: Date
    
    var agentName: String? {
        switch sender {
        case .agent(let agent):
            return agent.name
        case .user:
            return nil
        case .system:
            return "Sistema"
        }
    }
    
    enum MessageSender {
        case user
        case agent(GroupAgent)
        case system
        
        var displayName: String {
            switch self {
            case .user:
                return "Tu"
            case .agent(let agent):
                return agent.name
            case .system:
                return "Sistema"
            }
        }
        
        var isUser: Bool {
            if case .user = self { return true }
            return false
        }
        
        var isAgent: Bool {
            if case .agent = self { return true }
            return false
        }
        
        var isSystem: Bool {
            if case .system = self { return true }
            return false
        }
        
        var icon: String {
            switch self {
            case .user:
                return "👤"
            case .agent(let agent):
                return agent.icon
            case .system:
                return "⚙️"
            }
        }
    }
}

// MARK: - GroupConversationEngine
class GroupConversationEngine {
    private let maxRounds = 8
    private let pauseBetweenMessages: UInt64 = 2_000_000_000 // 2 secondi
    private let thinkingPause: UInt64 = 1_000_000_000 // 1 secondo
    
    func orchestrateGroupDiscussion(
        initialPrompt: String,
        participants: [GroupAgent],
        messageHandler: @escaping (GroupMessage) async -> Void,
        speakerUpdateHandler: @escaping (GroupAgent?) async -> Void
    ) async {
        var conversationHistory: [GroupMessage] = []
        var currentRound = 0
        
        // Messaggio di benvenuto
        let welcomeMessage = GroupMessage(
            content: "🎯 Discussione avviata! I nostri \(participants.count) esperti inizieranno a collaborare per rispondere alla tua richiesta.",
            sender: .system,
            timestamp: Date()
        )
        await messageHandler(welcomeMessage)
        
        while currentRound < maxRounds {
            let nextAgent = selectNextAgent(participants, round: currentRound, history: conversationHistory)
            
            // Aggiorna speaker corrente
            await speakerUpdateHandler(nextAgent)
            
            // Pausa per "thinking"
            try? await Task.sleep(nanoseconds: thinkingPause)
            
            do {
                let response = try await nextAgent.generateResponse(
                    to: initialPrompt,
                    context: conversationHistory
                )
                
                let message = GroupMessage(
                    content: response,
                    sender: .agent(nextAgent),
                    timestamp: Date()
                )
                
                conversationHistory.append(message)
                await messageHandler(message)
                
                // Pausa realistica tra messaggi
                try await Task.sleep(nanoseconds: pauseBetweenMessages)
                
                if shouldEndConversation(response, round: currentRound) {
                    break
                }
                
            } catch {
                print("Errore nella generazione risposta per \(nextAgent.name): \(error)")
                
                let errorMessage = GroupMessage(
                    content: "⚠️ \(nextAgent.name) ha riscontrato un problema tecnico e non può partecipare in questo momento.",
                    sender: .system,
                    timestamp: Date()
                )
                await messageHandler(errorMessage)
            }
            
            currentRound += 1
        }
        
        // Messaggio di chiusura
        await speakerUpdateHandler(nil)
        let closingMessage = GroupMessage(
            content: "✅ Discussione completata! Il team ha esplorato diverse prospettive e fornito un'analisi completa.",
            sender: .system,
            timestamp: Date()
        )
        await messageHandler(closingMessage)
    }
    
    private func selectNextAgent(
        _ participants: [GroupAgent],
        round: Int,
        history: [GroupMessage]
    ) -> GroupAgent {
        // Strategia di selezione intelligente
        if round == 0 {
            // Primo round: inizia con lo strategist se presente, altrimenti primo agente
            return participants.first { $0.name == "Strategist" } ?? participants[0]
        }
        
        // Evita ripetizioni consecutive
        let lastSpeaker = history.last?.sender
        let availableAgents = participants.filter { agent in
            if case .agent(let lastAgent) = lastSpeaker {
                return agent.id != lastAgent.id
            }
            return true
        }
        
        guard !availableAgents.isEmpty else {
            return participants[round % participants.count]
        }
        
        // Routing intelligente basato sul contenuto dell'ultimo messaggio
        let lastMessage = history.last?.content.lowercased() ?? ""
        
        if lastMessage.contains("dati") || lastMessage.contains("analisi") || lastMessage.contains("statistiche") {
            return availableAgents.first { $0.name == "Data Analyst" } ?? availableAgents.randomElement()!
        } else if lastMessage.contains("creativo") || lastMessage.contains("innovativo") || lastMessage.contains("design") {
            return availableAgents.first { $0.name == "Creative Director" } ?? availableAgents.randomElement()!
        } else if lastMessage.contains("tecnico") || lastMessage.contains("implementazione") || lastMessage.contains("codice") {
            return availableAgents.first { $0.name == "Tech Lead" } ?? availableAgents.randomElement()!
        } else if lastMessage.contains("problema") || lastMessage.contains("rischio") || lastMessage.contains("critica") {
            return availableAgents.first { $0.name == "Critic" } ?? availableAgents.randomElement()!
        } else if lastMessage.contains("sicurezza") || lastMessage.contains("privacy") {
            return availableAgents.first { $0.name == "Security Expert" } ?? availableAgents.randomElement()!
        } else if lastMessage.contains("futuro") || lastMessage.contains("innovazione") {
            return availableAgents.first { $0.name == "Innovator" } ?? availableAgents.randomElement()!
        }
        
        // Default: rotazione sequenziale
        return availableAgents[round % availableAgents.count]
    }
    
    private func shouldEndConversation(_ response: String, round: Int) -> Bool {
        let endKeywords = [
            "conclusione", "riassumendo", "in sintesi", "per concludere",
            "in conclusion", "to summarize", "in summary", "to conclude",
            "finalmente", "quindi", "pertanto"
        ]
        
        let hasEndKeyword = endKeywords.contains { response.lowercased().contains($0) }
        let isLongEnoughConversation = round >= 3
        let isMaxRounds = round >= maxRounds - 1
        
        return (hasEndKeyword && isLongEnoughConversation) || isMaxRounds
    }
}