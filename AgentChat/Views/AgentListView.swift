import SwiftUI

// MARK: - Agent List View
struct AgentListView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var manager: AgentManager = .shared

    @State private var showingAdd = false
    @State private var agentToEdit: Agent?

    var body: some View {
        NavigationStack {
            List {
                ForEach(manager.agents) { agent in
                    VStack(alignment: .leading) {
                        Text(agent.name).font(.headline)
                        if !agent.description.isEmpty {
                            Text(agent.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .contextMenu {
                        Button("Duplica") { manager.duplicateAgent(agent) }
                        Button("Modifica") { agentToEdit = agent }
                        Button(role: .destructive) {
                            manager.deleteAgent(agent)
                        } label: {
                            Text("Elimina")
                        }
                    }
                }
                .onDelete { indexes in
                    indexes.map { manager.agents[$0] }.forEach(manager.deleteAgent)
                }
            }
            .navigationTitle("Agenti")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Chiudi") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingAdd = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAdd) {
                AgentEditView(agent: Agent(name: "")) { agent in
                    manager.addAgent(agent)
                }
            }
            .sheet(item: $agentToEdit) { agent in
                AgentEditView(agent: agent) { updated in
                    manager.updateAgent(updated)
                }
            }
        }
    }
}

#Preview {
    AgentListView()
}
