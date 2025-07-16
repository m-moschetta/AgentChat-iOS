//
//  AddAgentView.swift
//  AgentChat
//
//  Created by OpenAI on 04/07/25.
//

import SwiftUI

// MARK: - Add / Edit Agent View
struct AddAgentView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var agentManager: AgentManager
    @StateObject private var configuration = LocalAssistantConfiguration()

    private let agent: Agent?

    @State private var name: String
    @State private var selectedProvider: AssistantProvider?
    @State private var systemPrompt: String
    @State private var avatar: String
    @State private var isActive: Bool

    init(agentManager: AgentManager, agent: Agent? = nil) {
        self.agentManager = agentManager
        self.agent = agent
        _name = State(initialValue: agent?.name ?? "")
        _selectedProvider = State(initialValue: agent?.provider)
        _systemPrompt = State(initialValue: agent?.systemPrompt ?? "")
        _avatar = State(initialValue: agent?.avatar ?? "🤖")
        _isActive = State(initialValue: agent?.isActive ?? true)
    }

    var body: some View {
        NavigationView {
            VStack {
                Form {
                    Section(header: Text("Informazioni Base")) {
                        TextField("Nome agente", text: $name)

                        Picker("Provider", selection: $selectedProvider) {
                            ForEach(configuration.availableProviders) { provider in
                                Text(provider.name).tag(Optional(provider))
                            }
                        }
                    }

                    Section(header: Text("Prompt")) {
                        TextField("System Prompt", text: $systemPrompt)
                    }

                    Section(header: Text("Avatar")) {
                        TextField("Emoji o SF Symbol", text: $avatar)
                    }

                    Section(header: Text("Stato")) {
                        Toggle("Agente attivo", isOn: $isActive)
                    }
                }
                
                HStack {
                    Button("Annulla") { 
                        dismiss() 
                    }
                    
                    Spacer()
                    
                    Button("Salva") { 
                        saveAgent() 
                    }
                    .disabled(!isFormValid)
                }
                .padding()
            }
            .navigationTitle(agent == nil ? "Nuovo Agente" : "Modifica Agente")
        }
    }

    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        selectedProvider != nil
    }

    private func saveAgent() {
        guard let provider = selectedProvider else { return }
        let newAgent = Agent(
            id: agent?.id ?? UUID().uuidString,
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            provider: provider,
            systemPrompt: systemPrompt.trimmingCharacters(in: .whitespacesAndNewlines),
            avatar: avatar.isEmpty ? "🤖" : avatar,
            isActive: isActive,
            isDefault: agent?.isDefault ?? false
        )

        if agent == nil {
            agentManager.addAgent(newAgent)
        } else {
            agentManager.updateAgent(newAgent)
        }

        dismiss()
    }
}

// MARK: - Preview
#Preview {
    AddAgentView(agentManager: AgentManager.shared)
}
