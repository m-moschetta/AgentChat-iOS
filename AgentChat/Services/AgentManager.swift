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
    private let userDefaultsKey = "custom_agents"

    private init() {
        loadAgents()
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
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
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
}
