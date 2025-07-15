import Foundation
import Combine

// MARK: - Agent Manager
class AgentManager: ObservableObject {
    static let shared = AgentManager()

    @Published private(set) var agents: [Agent] = []

    private let userDefaults = UserDefaults.standard
    private let storageKey = "agents"

    private init() {
        loadAgents()
    }

    // MARK: - CRUD Operations
    func addAgent(_ agent: Agent) {
        agents.append(agent)
        saveAgents()
    }

    func updateAgent(_ agent: Agent) {
        guard let index = agents.firstIndex(where: { $0.id == agent.id }) else { return }
        agents[index] = agent
        saveAgents()
    }

    func deleteAgent(_ agent: Agent) {
        agents.removeAll { $0.id == agent.id }
        saveAgents()
    }

    func duplicateAgent(_ agent: Agent) {
        var copy = agent
        copy = Agent(id: UUID(), name: agent.name + " Copy", description: agent.description, instructions: agent.instructions)
        agents.append(copy)
        saveAgents()
    }

    // MARK: - Persistence
    private func loadAgents() {
        guard let data = userDefaults.data(forKey: storageKey) else { return }
        if let decoded = try? JSONDecoder().decode([Agent].self, from: data) {
            agents = decoded
        }
    }

    private func saveAgents() {
        if let data = try? JSONEncoder().encode(agents) {
            userDefaults.set(data, forKey: storageKey)
        }
    }
}
