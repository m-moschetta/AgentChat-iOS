//
//  NewChatView.swift
//  AgentChat
//
//  Created by Mario Moschetta on 04/07/25.
//

import SwiftUI

struct NewChatView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var config = LocalAssistantConfiguration()
    @ObservedObject var workflowManager: N8NWorkflowManager
    @StateObject private var agentConfigManager = AgentConfigurationManager.shared
    
    @State private var selectedProvider: AssistantProvider?
    @State private var selectedModel: String?
    @State private var selectedWorkflow: N8NWorkflow?
    @State private var selectedAgent: AgentConfiguration?
    @State private var showingCustomProviderView = false
    @State private var showingAPIKeyConfig = false
    @State private var showingAgentConfig = false
    @State private var providerNeedingAPIKey: AssistantProvider?
    
    let onChatCreated: (AssistantProvider, String?, N8NWorkflow?) -> Void
    let onAgentChatCreated: ((AgentConfiguration) -> Void)?
    
    var availableProviders: [AssistantProvider] {
        config.activeProviders
    }
    
    var multiAgentProviders: [AssistantProvider] {
        [
            AssistantProvider(
                id: "hybrid_multi_agent",
                name: "Hybrid Multi-Agent",
                type: .custom,
                endpoint: "",
                apiKeyRequired: false,
                supportedModels: ["hybrid-fast", "hybrid-balanced", "hybrid-deep", "hybrid-creative"],
                defaultModel: "hybrid-balanced",
                icon: "brain.head.profile.fill",
                description: "Sistema ibrido che combina elaborazione locale e remota per risposte ottimali"
            ),
            AssistantProvider(
                id: "agent_group",
                name: "Agent Group Chat",
                type: .custom,
                endpoint: "",
                apiKeyRequired: false,
                supportedModels: ["group-discussion", "collaborative-analysis", "team-brainstorming"],
                defaultModel: "group-discussion",
                icon: "person.3.fill",
                description: "Conversazioni collaborative tra team di agenti specializzati"
            )
        ]
    }
    
    var selectedProviderModels: [String] {
        selectedProvider?.supportedModels ?? []
    }
    
    var body: some View {
        NavigationView {
            Form {
                TraditionalAssistantsSection(
                    selectedProvider: $selectedProvider,
                    selectedModel: $selectedModel,
                    selectedAgent: $selectedAgent,
                    selectedWorkflow: $selectedWorkflow,
                    providerNeedingAPIKey: $providerNeedingAPIKey,
                    showingAPIKeyConfig: $showingAPIKeyConfig,
                    showingCustomProviderView: $showingCustomProviderView,
                    config: config
                )
                
                MultiAgentSystemsSection(
                    selectedProvider: $selectedProvider,
                    selectedModel: $selectedModel,
                    selectedAgent: $selectedAgent,
                    selectedWorkflow: $selectedWorkflow,
                    multiAgentProviders: multiAgentProviders
                )
                
                CustomAgentsSection(
                    selectedAgent: $selectedAgent,
                    selectedProvider: $selectedProvider,
                    selectedModel: $selectedModel,
                    selectedWorkflow: $selectedWorkflow,
                    showingAgentConfig: $showingAgentConfig,
                    agentConfigManager: agentConfigManager
                )
                
                if !workflowManager.availableWorkflows.isEmpty {
                    N8NWorkflowsSection(
                        selectedWorkflow: $selectedWorkflow,
                        selectedProvider: $selectedProvider,
                        selectedModel: $selectedModel,
                        selectedAgent: $selectedAgent,
                        workflowManager: workflowManager
                    )
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Nuova Conversazione")
            .navigationBarItems(leading: Button("Annulla") { dismiss() }, trailing: startChatButton)
            .sheet(isPresented: $showingCustomProviderView) {
                CustomProviderView()
            }
            .sheet(isPresented: $showingAPIKeyConfig) {
                if let provider = providerNeedingAPIKey {
                    APIKeyConfigView(provider: provider)
                }
            }
            .sheet(isPresented: $showingAgentConfig) {
                AgentEditView(agent: nil, onSave: { newAgent in
                    agentConfigManager.addAgent(newAgent)
                    selectedAgent = newAgent
                    selectedProvider = nil
                    selectedModel = nil
                    selectedWorkflow = nil
                })
            }
        }
    }
    
    @ViewBuilder
    private var startChatButton: some View {
        if let agent = selectedAgent {
            Button("Inizia") {
                onAgentChatCreated?(agent)
                dismiss()
            }
        } else if let provider = selectedProvider {
            Button("Inizia") {
                onChatCreated(provider, selectedModel, selectedWorkflow)
                dismiss()
            }
            .disabled(selectedModel == nil && selectedWorkflow == nil)
        } else if let workflow = selectedWorkflow {
            Button("Inizia") {
                // Assumiamo che un workflow non richieda un provider specifico per iniziare
                // Potrebbe essere necessario un provider fittizio o una gestione diversa
                let dummyProvider = AssistantProvider(id: "n8n_workflow_runner", name: "N8N Runner", type: .custom, endpoint: "", apiKeyRequired: false, supportedModels: [], icon: "figure.flowchart", description: "")
                onChatCreated(dummyProvider, nil, workflow)
                dismiss()
            }
        } else {
            Button("Inizia") {
                // Non dovrebbe accadere se la UI è corretta
            }
            .disabled(true)
        }
    }
}

// MARK: - N8N Workflows Section
struct N8NWorkflowsSection: View {
    @Binding var selectedWorkflow: N8NWorkflow?
    @Binding var selectedProvider: AssistantProvider?
    @Binding var selectedModel: String?
    @Binding var selectedAgent: AgentConfiguration?
    
    @ObservedObject var workflowManager: N8NWorkflowManager
    
    var body: some View {
        Section {
            ForEach(workflowManager.availableWorkflows, id: \.id) { workflow in
                WorkflowRow(
                    workflow: workflow,
                    isSelected: selectedWorkflow?.id == workflow.id
                ) {
                    selectedWorkflow = workflow
                    selectedProvider = nil
                    selectedModel = nil
                    selectedAgent = nil
                }
            }
        } header: {
            Text("Workflow n8n")
        } footer: {
            Text("Automatizza i task con i workflow di n8n")
        }
    }
}

// MARK: - Custom Agents Section
struct CustomAgentsSection: View {
    @Binding var selectedAgent: AgentConfiguration?
    @Binding var selectedProvider: AssistantProvider?
    @Binding var selectedModel: String?
    @Binding var selectedWorkflow: N8NWorkflow?
    @Binding var showingAgentConfig: Bool
    
    @ObservedObject var agentConfigManager: AgentConfigurationManager
    
    var body: some View {
        Section {
            if agentConfigManager.agents.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    Text("Nessun agente configurato")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button("Crea il tuo primo agente") {
                        showingAgentConfig = true
                    }
                    .buttonStyle(.bordered)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            } else {
                ForEach(agentConfigManager.agents, id: \.id) { agent in
                    AgentRow(
                        agent: agent,
                        isSelected: selectedAgent?.id == agent.id
                    ) {
                        selectedAgent = agent
                        selectedProvider = nil
                        selectedModel = nil
                        selectedWorkflow = nil
                    }
                }
                
                Button("Crea nuovo agente") {
                    showingAgentConfig = true
                }
                .foregroundColor(.accentColor)
            }
        } header: {
            Text("Agenti Personalizzati")
        } footer: {
            Text("Agenti configurabili con ruoli, personalità e memoria personalizzati")
        }
    }
}

// MARK: - Multi-Agent Systems Section
struct MultiAgentSystemsSection: View {
    @Binding var selectedProvider: AssistantProvider?
    @Binding var selectedModel: String?
    @Binding var selectedAgent: AgentConfiguration?
    @Binding var selectedWorkflow: N8NWorkflow?
    
    let multiAgentProviders: [AssistantProvider]
    
    var body: some View {
        Section {
            ForEach(multiAgentProviders) { provider in
                ProviderRow(
                    provider: provider,
                    isSelected: selectedProvider?.id == provider.id,
                    hasValidAPIKey: true
                ) {
                    selectedProvider = provider
                    selectedModel = provider.defaultModel
                    selectedWorkflow = nil
                    selectedAgent = nil
                }
            }
        } header: {
            Text("Sistemi Multi-Agente")
        } footer: {
            Text("Sistemi avanzati che utilizzano più agenti per elaborazioni complesse e collaborative")
        }
    }
}

// MARK: - Traditional Assistants Section
struct TraditionalAssistantsSection: View {
    @Binding var selectedProvider: AssistantProvider?
    @Binding var selectedModel: String?
    @Binding var selectedAgent: AgentConfiguration?
    @Binding var selectedWorkflow: N8NWorkflow?
    @Binding var providerNeedingAPIKey: AssistantProvider?
    @Binding var showingAPIKeyConfig: Bool
    @Binding var showingCustomProviderView: Bool
    
    @ObservedObject var config: LocalAssistantConfiguration
    
    var availableProviders: [AssistantProvider] {
        config.activeProviders
    }
    
    var body: some View {
        Section {
            if availableProviders.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    
                    Text("Nessun provider disponibile")
                        .font(.headline)
                    
                    Text("Aggiungi un provider personalizzato per iniziare")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button("Aggiungi Provider") {
                        showingCustomProviderView = true
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                ForEach(availableProviders) { provider in
                    ProviderRow(
                        provider: provider,
                        isSelected: selectedProvider?.id == provider.id,
                        hasValidAPIKey: config.hasValidAPIKey(for: provider)
                    ) {
                        selectedProvider = provider
                        selectedModel = provider.defaultModel
                        selectedAgent = nil
                        selectedWorkflow = nil
                        
                        if provider.apiKeyRequired && !config.hasValidAPIKey(for: provider) {
                            providerNeedingAPIKey = provider
                            showingAPIKeyConfig = true
                        }
                    }
                }
            }
        } header: {
            Text("Assistenti AI Tradizionali")
        } footer: {
            if !availableProviders.isEmpty {
                Button("Aggiungi provider personalizzato") {
                    showingCustomProviderView = true
                }
                .font(.footnote)
            }
        }
    }
}

// MARK: - Preview
struct NewChatView_Previews: PreviewProvider {
    static var previews: some View {
        NewChatView(
            workflowManager: N8NWorkflowManager.shared,
            onChatCreated: { provider, model, workflow in
                print("Chat created with \(provider.name) using model \(model ?? "default") and workflow \(workflow?.name ?? "none")")
            },
            onAgentChatCreated: { agentConfig in
                print("Agent chat created with \(agentConfig.name)")
            }
        )
    }
}