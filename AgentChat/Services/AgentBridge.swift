//
//  AgentBridge.swift
//  AgentChat
//
//  Created by Mario Moschetta on 04/07/25.
//

import Foundation
import Combine

// MARK: - Agent Bridge
/// Bridge per unificare Agent e AgentConfiguration evitando duplicazioni
class AgentBridge: ObservableObject {
    static let shared = AgentBridge()
    
    private init() {
        // Migra automaticamente gli agenti dal vecchio sistema al nuovo
        migrateAgentsIfNeeded()
    }
    
    // MARK: - Migration Methods
    
    /// Migra gli agenti dal sistema Agent al sistema AgentConfiguration
    private func migrateAgentsIfNeeded() {
        let legacyAgents = AgentManager.shared.agents
        
        if !legacyAgents.isEmpty {
            print("Migrazione di \(legacyAgents.count) agenti dal sistema legacy...")
            
            for legacyAgent in legacyAgents {
                let migratedAgent = convertToAgentConfiguration(legacyAgent)
                
                // Aggiungi solo se non esiste già
                if !AgentConfigurationManager.shared.agents.contains(where: { $0.name == migratedAgent.name }) {
                    AgentConfigurationManager.shared.addAgent(migratedAgent)
                }
            }
            
            // Pulisci il sistema legacy dopo la migrazione
            AgentManager.shared.reset()
            print("Migrazione completata. Sistema legacy pulito.")
        }
    }
    
    /// Converte un Agent in AgentConfiguration
    private func convertToAgentConfiguration(_ agent: Agent) -> AgentConfiguration {
        return AgentConfiguration(
            name: agent.name,
            systemPrompt: agent.systemPrompt,
            personality: "Migrato dal sistema legacy",
            role: "Agente Personalizzato",
            icon: agent.avatar,
            preferredProvider: agent.provider.type.rawValue,
            temperature: 0.7,
            maxTokens: 2000,
            isActive: agent.isActive,
            memoryEnabled: true,
            contextWindow: 10
        )
    }
    
    // MARK: - Unified Agent Access
    
    /// Ottieni tutti gli agenti attivi dal sistema unificato
    func getAllActiveAgents() -> [AgentConfiguration] {
        return AgentConfigurationManager.shared.getActiveAgents()
    }
    
    /// Ottieni un agente per ID
    func getAgent(withId id: UUID) -> AgentConfiguration? {
        return AgentConfigurationManager.shared.getAgent(withId: id)
    }
    
    /// Aggiungi un nuovo agente
    func addAgent(_ agent: AgentConfiguration) {
        AgentConfigurationManager.shared.addAgent(agent)
    }
    
    /// Aggiorna un agente esistente
    func updateAgent(_ agent: AgentConfiguration) {
        AgentConfigurationManager.shared.updateAgent(agent)
    }
    
    /// Elimina un agente
    func deleteAgent(_ agent: AgentConfiguration) {
        AgentConfigurationManager.shared.deleteAgent(agent)
    }
    
    /// Verifica se il sistema legacy ha ancora dati
    func hasLegacyData() -> Bool {
        return !AgentManager.shared.agents.isEmpty
    }
    
    /// Forza una nuova migrazione (per debug)
    func forceMigration() {
        migrateAgentsIfNeeded()
    }
}

// MARK: - Migration Extensions
extension AgentBridge {
    
    /// Esporta la configurazione completa del sistema
    func exportSystemConfiguration() -> Data? {
        let configuration = SystemConfiguration(
            agents: AgentConfigurationManager.shared.agents,
            migrationVersion: "1.0",
            exportDate: Date()
        )
        
        do {
            return try JSONEncoder().encode(configuration)
        } catch {
            print("Errore nell'esportazione della configurazione: \(error)")
            return nil
        }
    }
    
    /// Importa la configurazione del sistema
    func importSystemConfiguration(from data: Data) -> Bool {
        do {
            let configuration = try JSONDecoder().decode(SystemConfiguration.self, from: data)
            
            // Sostituisci la configurazione corrente
            AgentConfigurationManager.shared.agents = configuration.agents
            
            print("Configurazione importata con successo. Versione: \(configuration.migrationVersion)")
            return true
        } catch {
            print("Errore nell'importazione della configurazione: \(error)")
            return false
        }
    }
}

// MARK: - System Configuration Model
private struct SystemConfiguration: Codable {
    let agents: [AgentConfiguration]
    let migrationVersion: String
    let exportDate: Date
}