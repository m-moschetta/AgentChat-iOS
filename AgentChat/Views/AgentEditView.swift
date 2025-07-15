import SwiftUI

// MARK: - Agent Edit View
struct AgentEditView: View {
    @Environment(\.dismiss) private var dismiss
    @State var agent: Agent
    let onSave: (Agent) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Nome")) {
                    TextField("Nome agente", text: $agent.name)
                }
                Section(header: Text("Descrizione")) {
                    TextField("Descrizione", text: $agent.description)
                }
                Section(header: Text("Istruzioni")) {
                    TextEditor(text: $agent.instructions)
                        .frame(minHeight: 150)
                }
            }
            .navigationTitle("Agente")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salva") {
                        onSave(agent)
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    AgentEditView(agent: Agent(name: "Test")) { _ in }
}
