//
//  AgentConfigurationManager.swift
//  AgentChat
//
//  Created by Mario Moschetta on 04/07/25.
//

import Foundation
import Combine

// MARK: - Agent Configuration Manager
class AgentConfigurationManager: ObservableObject {
    static let shared = AgentConfigurationManager()
    
    @Published var agents: [AgentConfiguration] = []
    
    private let userDefaults = UserDefaults.standard
    private let agentsKey = "configured_agents"
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        loadAgents()
        
        // Auto-save quando gli agenti cambiano
        $agents
            .dropFirst() // Ignora il primo valore (caricamento iniziale)
            .sink { [weak self] _ in
                self?.saveAgents()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    func loadAgents() {
        if let data = userDefaults.data(forKey: agentsKey),
           let decodedAgents = try? JSONDecoder().decode([AgentConfiguration].self, from: data) {
            agents = decodedAgents
        } else {
            // Prima volta: carica agenti di default
            agents = AgentConfiguration.defaultAgents
            saveAgents()
        }
    }
    
    func saveAgents() {
        do {
            let encoded = try JSONEncoder().encode(agents)
            userDefaults.set(encoded, forKey: agentsKey)
        } catch {
            print("Errore nel salvare gli agenti: \(error)")
        }
    }
    
    func addAgent(_ agent: AgentConfiguration) {
        agents.append(agent)
    }
    
    func updateAgent(_ updatedAgent: AgentConfiguration) {
        if let index = agents.firstIndex(where: { $0.id == updatedAgent.id }) {
            agents[index] = updatedAgent
        }
    }
    
    func deleteAgent(_ agent: AgentConfiguration) {
        agents.removeAll { $0.id == agent.id }
    }
    
    func deleteAgent(withId id: UUID) {
        agents.removeAll { $0.id == id }
    }
    
    func getAgent(withId id: UUID) -> AgentConfiguration? {
        return agents.first { $0.id == id }
    }
    
    func getActiveAgents() -> [AgentConfiguration] {
        return agents.filter { $0.isActive }
    }
    
    func getAgentsByProvider(_ provider: String) -> [AgentConfiguration] {
        return agents.filter { $0.preferredProvider == provider }
    }
    
    func toggleAgentStatus(_ agent: AgentConfiguration) {
        if let index = agents.firstIndex(where: { $0.id == agent.id }) {
            agents[index].isActive.toggle()
        }
    }
    
    func duplicateAgent(_ agent: AgentConfiguration) -> AgentConfiguration {
        let duplicated = AgentConfiguration(
            name: "\(agent.name) (Copia)",
            systemPrompt: agent.systemPrompt,
            personality: agent.personality,
            role: agent.role,
            icon: agent.icon,
            preferredProvider: agent.preferredProvider,
            temperature: agent.temperature,
            maxTokens: agent.maxTokens,
            isActive: false, // Inizialmente disattivato
            memoryEnabled: agent.memoryEnabled,
            contextWindow: agent.contextWindow
        )
        
        addAgent(duplicated)
        return duplicated
    }
    
    func resetToDefaults() {
        agents = AgentConfiguration.defaultAgents
    }
    
    func exportAgents() -> Data? {
        do {
            return try JSONEncoder().encode(agents)
        } catch {
            print("Errore nell'esportazione degli agenti: \(error)")
            return nil
        }
    }
    
    func importAgents(from data: Data) -> Bool {
        do {
            let importedAgents = try JSONDecoder().decode([AgentConfiguration].self, from: data)
            
            // Aggiungi gli agenti importati (evita duplicati per nome)
            for importedAgent in importedAgents {
                if !agents.contains(where: { $0.name == importedAgent.name }) {
                    var newAgent = importedAgent
                    newAgent.isActive = false // Inizialmente disattivati
                    addAgent(newAgent)
                }
            }
            
            return true
        } catch {
            print("Errore nell'importazione degli agenti: \(error)")
            return false
        }
    }
    
    // MARK: - Validation
    
    func validateAgentConfiguration(_ agent: AgentConfiguration) -> [String] {
        var errors: [String] = []
        
        if agent.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("Il nome dell'agente non può essere vuoto")
        }
        
        if agent.systemPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("Il system prompt non può essere vuoto")
        }
        
        if agent.role.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("Il ruolo non può essere vuoto")
        }
        
        if agent.temperature < 0.0 || agent.temperature > 2.0 {
            errors.append("La temperatura deve essere tra 0.0 e 2.0")
        }
        
        if agent.maxTokens < 100 || agent.maxTokens > 10000 {
            errors.append("Il numero massimo di token deve essere tra 100 e 10000")
        }
        
        if agent.contextWindow < 1 || agent.contextWindow > 50 {
            errors.append("La finestra di contesto deve essere tra 1 e 50 messaggi")
        }
        
        // Verifica che il provider sia supportato
        let supportedProviders = ["OpenAI", "Claude", "Mistral", "Perplexity", "Grok", "Custom"]
        if !supportedProviders.contains(agent.preferredProvider) {
            errors.append("Provider non supportato: \(agent.preferredProvider)")
        }
        
        return errors
    }
    
    func isAgentNameUnique(_ name: String, excludingId: UUID? = nil) -> Bool {
        return !agents.contains { agent in
            agent.name.lowercased() == name.lowercased() && agent.id != excludingId
        }
    }
}

// MARK: - Agent Configuration Manager Extensions
extension AgentConfigurationManager {
    
    // Metodo di convenienza per ottenere un agente per chat singola
    func getDefaultSingleChatAgent() -> AgentConfiguration? {
        return getActiveAgents().first { $0.name == "Assistente Generale" }
    }
    
    // Metodo per ottenere agenti adatti per chat di gruppo
    func getGroupChatAgents() -> [AgentConfiguration] {
        return getActiveAgents().filter { agent in
            // Esclude agenti troppo specifici per chat di gruppo
            !agent.role.lowercased().contains("tutor") &&
            !agent.role.lowercased().contains("personale")
        }
    }
    
    // Statistiche sugli agenti
    func getAgentStatistics() -> (total: Int, active: Int, byProvider: [String: Int]) {
        let total = agents.count
        let active = getActiveAgents().count
        
        var byProvider: [String: Int] = [:]
        for agent in agents {
            byProvider[agent.preferredProvider, default: 0] += 1
        }
        
        return (total: total, active: active, byProvider: byProvider)
    }
}