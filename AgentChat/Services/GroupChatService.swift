//
//  GroupChatService.swift
//  AgentChat
//
//  Created by Mario Moschetta on 04/07/25.
//

import Foundation
import Combine

// MARK: - GroupChatService
class GroupChatService: ChatServiceProtocol {
    static let shared = GroupChatService()
    
    private let conversationEngine = GroupConversationEngine()
    private var activeGroups: [UUID: AgentGroup] = [:]
    
    private init() {}
    
    // MARK: - ChatServiceProtocol Implementation
    var supportedModels: [String] {
        AgentGroupTemplate.allTemplates.map { $0.name }
    }
    
    var providerName: String { "Agent Group Chat" }
    
    func sendMessage(_ message: String, model: String?) async throws -> String {
        let templateName = model ?? "Product Team"
        
        // Trova o crea il template
        guard let template = AgentGroupTemplate.allTemplates.first(where: { $0.name == templateName }) else {
            throw GroupChatError.templateNotFound(templateName)
        }
        
        // Crea un nuovo gruppo se non esiste
        let groupId = UUID()
        let group = AgentGroup(
            name: template.name,
            description: template.description,
            icon: template.icon,
            participants: template.participants,
            agentType: .agentGroup
        )
        
        activeGroups[groupId] = group
        
        // Avvia la conversazione di gruppo
        return try await startGroupConversation(group: group, initialMessage: message)
    }
    
    func validateConfiguration() async throws {
        // Il servizio di gruppo è sempre disponibile
    }
    
    // MARK: - ChatServiceProtocol Implementation
    func sendMessage(_ message: String, configuration: AgentConfiguration) async throws -> String {
        // Usa il modello dalla configurazione come template name
        return try await sendMessage(message, model: configuration.model)
    }
    
    // MARK: - Group Management
    func createGroup(from template: AgentGroupTemplate, customName: String? = nil) -> AgentGroup {
        let groupId = UUID()
        let group = AgentGroup(
            name: customName ?? template.name,
            description: template.description,
            icon: template.icon,
            participants: template.participants,
            agentType: .group
        )
        
        activeGroups[groupId] = group
        return group
    }
    
    func getActiveGroup(id: UUID) -> AgentGroup? {
        return activeGroups[id]
    }
    
    func removeGroup(id: UUID) {
        activeGroups.removeValue(forKey: id)
    }
    
    // MARK: - Private Methods
    private func startGroupConversation(group: AgentGroup, initialMessage: String) async throws -> String {
        // Avvia la conversazione di gruppo usando il metodo integrato
        await group.startGroupConversation(with: initialMessage)
        
        // Restituisci un riassunto della discussione
        return generateDiscussionSummary(responses: group.messages, groupName: group.name)
    }
    
    private func generateDiscussionSummary(responses: [GroupMessage], groupName: String) -> String {
        let participantCount = Set(responses.compactMap { $0.agentName }).count
        let totalMessages = responses.count
        
        var summary = """
        🎯 **Discussione \(groupName) Completata**
        
        👥 **Partecipanti attivi:** \(participantCount)
        💬 **Messaggi totali:** \(totalMessages)
        
        **📋 Punti chiave emersi:**
        """
        
        // Estrai i punti chiave dalle risposte
        let keyPoints = extractKeyPoints(from: responses)
        for (index, point) in keyPoints.enumerated() {
            summary += "\n\(index + 1). \(point)"
        }
        
        summary += "\n\n**🔄 Conversazione completa disponibile nella chat di gruppo.**"
        
        return summary
    }
    
    private func extractKeyPoints(from responses: [GroupMessage]) -> [String] {
        var keyPoints: [String] = []
        
        for response in responses {
            let content = response.content
            
            // Cerca pattern di punti chiave
            if content.contains("raccomando") || content.contains("suggerisco") {
                let point = extractSentenceContaining(content, keywords: ["raccomando", "suggerisco"])
                if let point = point {
                    keyPoints.append("💡 \(point)")
                }
            }
            
            if content.contains("problema") || content.contains("rischio") {
                let point = extractSentenceContaining(content, keywords: ["problema", "rischio"])
                if let point = point {
                    keyPoints.append("⚠️ \(point)")
                }
            }
            
            if content.contains("opportunità") || content.contains("vantaggio") {
                let point = extractSentenceContaining(content, keywords: ["opportunità", "vantaggio"])
                if let point = point {
                    keyPoints.append("🚀 \(point)")
                }
            }
        }
        
        return Array(keyPoints.prefix(5)) // Limita a 5 punti chiave
    }
    
    private func extractSentenceContaining(_ text: String, keywords: [String]) -> String? {
        let sentences = text.components(separatedBy: CharacterSet(charactersIn: ".!?"))
        
        for sentence in sentences {
            let lowercased = sentence.lowercased()
            if keywords.contains(where: { lowercased.contains($0) }) {
                return sentence.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        
        return nil
    }
}



// MARK: - GroupChatError
enum GroupChatError: LocalizedError {
    case templateNotFound(String)
    case groupNotFound(UUID)
    case invalidConfiguration
    case conversationFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .templateNotFound(let name):
            return "Template '\(name)' non trovato"
        case .groupNotFound(let id):
            return "Gruppo con ID \(id) non trovato"
        case .invalidConfiguration:
            return "Configurazione del gruppo non valida"
        case .conversationFailed(let reason):
            return "Conversazione fallita: \(reason)"
        }
    }
}

// MARK: - GroupMessage Extensions
extension GroupMessage {
    var isFromUser: Bool {
        switch sender {
        case .user:
            return true
        default:
            return false
        }
    }
    
    var isFromAgent: Bool {
        switch sender {
        case .agent:
            return true
        default:
            return false
        }
    }
    
    var isFromSystem: Bool {
        switch sender {
        case .system:
            return true
        default:
            return false
        }
    }
    
    var displayName: String {
        return agentName ?? "Utente"
    }
    
    var shortPreview: String {
        let maxLength = 50
        if content.count <= maxLength {
            return content
        }
        return String(content.prefix(maxLength)) + "..."
    }
}

// MARK: - AgentGroup Extensions
extension AgentGroup {
    var lastMessage: GroupMessage? {
        return messages.last
    }
    
    var messageCount: Int {
        return messages.count
    }
    
    var participantNames: [String] {
        return participants.map { $0.name }
    }
    
    func getParticipant(named name: String) -> GroupAgent? {
        return participants.first { $0.name == name }
    }
}