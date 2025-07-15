//
//  NewChatView.swift
//  AgentChat
//
//  Created by Mario Moschetta on 04/07/25.
//

import SwiftUI

// MARK: - New Chat View
struct NewChatView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var config = LocalAssistantConfiguration()
    @ObservedObject var workflowManager: N8NWorkflowManager
    @StateObject private var agentManager = AgentManager.shared

    @State private var selectedProvider: AssistantProvider?
    @State private var selectedModel: String?
    @State private var selectedWorkflow: N8NWorkflow?
    @State private var selectedAgent: Agent?
    @State private var showingCustomProviderView = false
    @State private var showingAPIKeyConfig = false
    @State private var providerNeedingAPIKey: AssistantProvider?
    @State private var showingAddAgentView = false

    let onChatCreated: (AssistantProvider, String?, N8NWorkflow?) -> Void
    
    var availableProviders: [AssistantProvider] {
        config.activeProviders
    }

    var availableAgents: [Agent] {
        agentManager.activeAgents
    }
    
    var selectedProviderModels: [String] {
        selectedProvider?.supportedModels ?? []
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Agents Section
                if !availableAgents.isEmpty {
                    Section {
                        ForEach(availableAgents) { agent in
                            AgentRow(
                                agent: agent,
                                isSelected: selectedAgent?.id == agent.id
                            ) {
                                selectedAgent = agent
                                selectedProvider = agent.provider
                                selectedModel = agent.provider.defaultModel
                                selectedWorkflow = nil
                            }
                        }
                    } header: {
                        Text("Agenti")
                    } footer: {
                        Button("Nuovo agente") { showingAddAgentView = true }
                            .font(.footnote)
                    }
                }

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
                                selectedAgent = nil
                                selectedProvider = provider
                                selectedModel = provider.defaultModel
                                
                                // Check if API key is needed
                                if provider.apiKeyRequired && !config.hasValidAPIKey(for: provider) {
                                    providerNeedingAPIKey = provider
                                    showingAPIKeyConfig = true
                                }
                            }
                        }
                    }
                } header: {
                    Text("Seleziona Assistente")
                } footer: {
                    if !availableProviders.isEmpty {
                        Button("Aggiungi provider personalizzato") {
                            showingCustomProviderView = true
                        }
                        .font(.footnote)
                    }
                }
                
                // Sezione Workflow n8n
                if !workflowManager.availableWorkflows.isEmpty {
                    Section {
                        ForEach(workflowManager.availableWorkflows) { workflow in
                            WorkflowRow(
                                workflow: workflow,
                                isSelected: selectedWorkflow?.id == workflow.id
                            ) {
                                selectedWorkflow = workflow
                                selectedAgent = nil
                                selectedProvider = nil
                                selectedModel = nil
                            }
                        }
                    } header: {
                        Text("Workflow n8n")
                    } footer: {
                        Text("I workflow n8n permettono di automatizzare processi complessi")
                    }
                }
                
                if let selectedProvider, !selectedProviderModels.isEmpty {
                    Section {
                        Picker("Modello", selection: Binding(
                            get: { selectedModel ?? selectedProvider.defaultModel ?? "" },
                            set: { selectedModel = $0 }
                        )) {
                            ForEach(selectedProviderModels, id: \.self) { model in
                                Text(model).tag(model)
                            }
                        }
                        .pickerStyle(.menu)
                    } header: {
                        Text("Modello")
                    } footer: {
                        if let model = selectedModel ?? selectedProvider.defaultModel {
                            Text("Modello selezionato: \(model)")
                        }
                    }
                }
                
                if let selectedProvider {
                    Section {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: selectedProvider.icon)
                                    .foregroundColor(.accentColor)
                                    .frame(width: 24)
                                VStack(alignment: .leading) {
                                    Text(selectedProvider.name)
                                        .font(.headline)
                                    Text(selectedProvider.type.displayName)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                
                                if selectedProvider.apiKeyRequired {
                                    if config.hasValidAPIKey(for: selectedProvider) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                    } else {
                                        Button("Configura") {
                                            providerNeedingAPIKey = selectedProvider
                                            showingAPIKeyConfig = true
                                        }
                                        .font(.caption)
                                        .buttonStyle(.bordered)
                                    }
                                }
                            }
                            
                            Text(selectedProvider.description)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            if selectedProvider.type == .n8n {
                                Label("Workflow di creazione blog automatizzato", systemImage: "doc.text")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.vertical, 4)
                    } header: {
                        Text("Dettagli Provider")
                    }
                }
                
                if let selectedWorkflow {
                    Section {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text(selectedWorkflow.icon)
                                    .font(.title2)
                                    .frame(width: 24)
                                VStack(alignment: .leading) {
                                    Text(selectedWorkflow.name)
                                        .font(.headline)
                                    Text(selectedWorkflow.category.displayName)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                
                                if selectedWorkflow.requiresAuthentication {
                                    Image(systemName: "key")
                                        .foregroundColor(.orange)
                                } else {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                }
                            }
                            
                            Text(selectedWorkflow.description)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Label("Endpoint: \(selectedWorkflow.endpoint)", systemImage: "link")
                                Label("Parametri: \(selectedWorkflow.parameters.count)", systemImage: "slider.horizontal.3")
                                if selectedWorkflow.parameters.filter({ $0.isRequired }).count > 0 {
                                    Label("Parametri obbligatori: \(selectedWorkflow.parameters.filter { $0.isRequired }.count)", systemImage: "exclamationmark.circle")
                                }
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        }
                        .padding(.vertical, 4)
                    } header: {
                        Text("Dettagli Workflow")
                    }
                }
            }
            .navigationTitle("Nuova Chat")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Crea") {
                        createChat()
                    }
                    .disabled(!canCreateChat)
                }
            }
            .sheet(isPresented: $showingCustomProviderView) {
                CustomProviderView()
            }
            .sheet(isPresented: $showingAddAgentView) {
                AddAgentView(agentManager: agentManager)
            }
            .sheet(item: $providerNeedingAPIKey) { provider in
                APIKeyConfigView(provider: provider)
            }
        }
    }
    
    // MARK: - Computed Properties
    private var canCreateChat: Bool {
        // Se è selezionato un workflow n8n
        if let selectedWorkflow {
            if selectedWorkflow.requiresAuthentication {
                // Verifica se c'è una API key per n8n nel keychain
                return KeychainService.shared.getAPIKey(for: "n8n_\(selectedWorkflow.id)") != nil
            }
            return true
        }
        
        if let selectedAgent {
            let provider = selectedAgent.provider
            if provider.apiKeyRequired {
                return config.hasValidAPIKey(for: provider)
            }
            return true
        }

        // Se è selezionato un provider tradizionale
        guard let selectedProvider else { return false }
        
        if selectedProvider.apiKeyRequired {
            return config.hasValidAPIKey(for: selectedProvider)
        }
        
        return true
    }
    
    // MARK: - Methods
    private func createChat() {
        if let selectedWorkflow {
            // Crea chat con workflow n8n
            let n8nProvider = AssistantProvider(
                id: "n8n_\(selectedWorkflow.id)",
                name: selectedWorkflow.name,
                type: .n8n,
                endpoint: selectedWorkflow.endpoint,
                apiKeyRequired: selectedWorkflow.requiresAuthentication,
                supportedModels: [],
                defaultModel: nil,
                icon: "gear.badge",
                description: selectedWorkflow.description
            )
            onChatCreated(n8nProvider, nil, selectedWorkflow)
        } else if let selectedAgent {
            let provider = selectedAgent.provider
            let model = selectedModel ?? provider.defaultModel
            onChatCreated(provider, model, nil)
        } else if let selectedProvider {
            // Crea chat con provider tradizionale
            let model = selectedModel ?? selectedProvider.defaultModel
            onChatCreated(selectedProvider, model, nil)
        }
        
        dismiss()
    }
}

// MARK: - Agent Row
struct AgentRow: View {
    let agent: Agent
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(agent.avatar)
                    .font(.title2)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 4) {
                    Text(agent.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(agent.provider.name)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentColor)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        )
    }
}

// MARK: - Provider Row
struct ProviderRow: View {
    let provider: AssistantProvider
    let isSelected: Bool
    let hasValidAPIKey: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: provider.icon)
                    .foregroundColor(isSelected ? .accentColor : .secondary)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(provider.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(provider.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                VStack(spacing: 4) {
                    if provider.apiKeyRequired {
                        Image(systemName: hasValidAPIKey ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                            .foregroundColor(hasValidAPIKey ? .green : .orange)
                            .font(.caption)
                    }
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.accentColor)
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        )
    }
}

// MARK: - Workflow Row
struct WorkflowRow: View {
    let workflow: N8NWorkflow
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(workflow.icon)
                    .font(.title2)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(workflow.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(workflow.category.displayName)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.2))
                            .foregroundColor(.blue)
                            .cornerRadius(4)
                    }
                    
                    Text(workflow.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                VStack(spacing: 4) {
                    if workflow.requiresAuthentication {
                        Image(systemName: "key")
                            .foregroundColor(.orange)
                            .font(.caption)
                    }
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.accentColor)
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        )
    }
}

// MARK: - Preview
#Preview {
    let workflowManager = N8NWorkflowManager.shared
    NewChatView(workflowManager: workflowManager) { provider, model, workflow in
        print("Chat created with \(provider.name) using model \(model ?? "default") and workflow \(workflow?.name ?? "none")")
    }
}