//
//  AgentManager.swift
//  AgentChat
//
//  Created by OpenAI on 04/07/25.
//

import Foundation
import Combine

// MARK: - Agent Manager
class AgentManager: ObservableObject {
    static let shared = AgentManager()

    @Published var agents: [Agent] = []
    @Published var agentGroups: [AgentGroup] = []
    private let userDefaultsKey = "custom_agents"
    private let groupsKey = "agent_groups"

    private init() {
        loadAgents()
        loadAgentGroups()
    }

    // MARK: - Public API
    func addAgent(_ agent: Agent) {
        agents.append(agent)
        saveAgents()
    }

    func updateAgent(_ agent: Agent) {
        guard let index = agents.firstIndex(where: { $0.id == agent.id }) else { return }
        agents[index] = agent
        saveAgents()
    }

    func removeAgent(id: String) {
        agents.removeAll { $0.id == id }
        saveAgents()
    }

    func toggleAgent(_ agent: Agent) {
        guard let index = agents.firstIndex(where: { $0.id == agent.id }) else { return }
        agents[index].isActive.toggle()
        saveAgents()
    }

    var activeAgents: [Agent] {
        agents.filter { $0.isActive }
    }

    func reset() {
        agents.removeAll()
        agentGroups.removeAll()
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
        UserDefaults.standard.removeObject(forKey: groupsKey)
    }
    
    func resetToDefaults() {
        reset()
    }
    
    func removeAgent(_ agent: Agent) {
        removeAgent(id: agent.id)
    }
    
    // MARK: - Agent Groups API
    func addAgentGroup(_ group: AgentGroup) {
        agentGroups.append(group)
        saveAgentGroups()
    }
    
    func removeAgentGroup(_ group: AgentGroup) {
        agentGroups.removeAll { $0.id == group.id }
        saveAgentGroups()
    }
    
    func updateAgentGroup(_ group: AgentGroup) {
        if let index = agentGroups.firstIndex(where: { $0.id == group.id }) {
            agentGroups[index] = group
            saveAgentGroups()
        }
    }

    // MARK: - Persistence
    private func loadAgents() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let saved = try? JSONDecoder().decode([Agent].self, from: data) else { return }
        agents = saved
    }

    private func saveAgents() {
        guard let data = try? JSONEncoder().encode(agents) else { return }
        UserDefaults.standard.set(data, forKey: userDefaultsKey)
    }
    
    private func loadAgentGroups() {
        guard let data = UserDefaults.standard.data(forKey: groupsKey),
              let saved = try? JSONDecoder().decode([AgentGroup].self, from: data) else { return }
        agentGroups = saved
    }
    
    private func saveAgentGroups() {
        guard let data = try? JSONEncoder().encode(agentGroups) else { return }
        UserDefaults.standard.set(data, forKey: groupsKey)
    }
}
