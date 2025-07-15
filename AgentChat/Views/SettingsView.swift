//
//  SettingsView.swift
//  AgentChat
//
//  Created by Mario Moschetta on 04/07/25.
//

import SwiftUI
import Foundation

// MARK: - Settings View
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var configuration = LocalAssistantConfiguration()
    @ObservedObject var workflowManager: N8NWorkflowManager
    
    @State private var showingCustomProviderView = false
    @State private var showingAPIKeyConfig = false
    @State private var selectedProviderForAPIKey: AssistantProvider?
    @State private var showingResetAlert = false
    @State private var showingAddWorkflowView = false
    @State private var selectedWorkflowForEdit: N8NWorkflow?
    
    var body: some View {
        NavigationStack {
            formContent
                .navigationTitle("Impostazioni")
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Fine") {
                            dismiss()
                        }
                    }
                }
                .sheet(isPresented: $showingCustomProviderView) {
                    CustomProviderView()
                }
                .sheet(item: $selectedProviderForAPIKey) { provider in
                    APIKeyConfigView(provider: provider)
                }
                .sheet(isPresented: $showingAddWorkflowView) {
                    AddN8NWorkflowView(workflowManager: workflowManager)
                }
                .sheet(item: $selectedWorkflowForEdit) { workflow in
                    AddN8NWorkflowView(workflowManager: workflowManager)
                }
                .alert("Ripristina Configurazione", isPresented: $showingResetAlert) {
                    Button("Annulla", role: .cancel) { }
                    Button("Ripristina", role: .destructive) {
                        configuration.resetToDefaults()
                    }
                } message: {
                    Text("Sei sicuro di voler ripristinare la configurazione predefinita? Questa azione non può essere annullata.")
                }
        }
    }
    
    private var formContent: some View {
        Form {
            providersSection
            addProviderSection
            workflowsSection
            statisticsSection
            resetSection
        }
    }
    
    private var providersSection: some View {
        Section {
            ForEach(configuration.availableProviders) { provider in
                ProviderSettingsRow(
                    provider: provider,
                    hasValidAPIKey: configuration.hasValidAPIKey(for: provider),
                    onToggle: {
                        configuration.toggleProvider(provider)
                    },
                    onConfigureAPIKey: {
                        selectedProviderForAPIKey = provider
                        showingAPIKeyConfig = true
                    },
                    onRemove: provider.type == .custom ? {
                        configuration.removeCustomProvider(withId: provider.id)
                    } : Optional<() -> Void>.none
                )
            }
        } header: {
            Text("Provider Configurati")
        } footer: {
            Text("Abilita o disabilita i provider AI. I provider disabilitati non appariranno nella selezione delle nuove chat.")
        }
    }
    
    private var addProviderSection: some View {
        Section {
            Button {
                showingCustomProviderView = true
            } label: {
                Label("Aggiungi Provider Personalizzato", systemImage: "plus.circle")
            }
        } header: {
            Text("Gestione Provider")
        }
    }
    
    private var workflowsSection: some View {
        Section {
            ForEach(workflowManager.availableWorkflows) { workflow in
                WorkflowSettingsRow(
                    workflow: workflow,
                    workflowManager: workflowManager,
                    onEdit: {
                        selectedWorkflowForEdit = workflow
                    },
                    onRemove: !workflow.isDefault ? {
                        workflowManager.removeWorkflow(withId: workflow.id)
                    } : Optional<() -> Void>.none
                )
            }
            
            Button {
                showingAddWorkflowView = true
            } label: {
                Label("Aggiungi Workflow n8n", systemImage: "plus.circle")
            }
        } header: {
            Text("Workflow n8n")
        } footer: {
            Text("Gestisci i workflow n8n personalizzati. I workflow predefiniti non possono essere rimossi.")
        }
    }
    
    private var statisticsSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text("Provider Attivi: \(configuration.activeProviders.count)")
                Text("Provider Totali: \(configuration.availableProviders.count)")
                Text("Provider Personalizzati: \(configuration.customProviders.count)")
                Divider()
                Text("Workflow n8n Attivi: \(workflowManager.activeWorkflows)")
                Text("Workflow n8n Totali: \(workflowManager.availableWorkflows.count)")
                Text("Workflow Personalizzati: \(workflowManager.customWorkflows)")
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
        } header: {
            Text("Statistiche")
        }
    }
    
    private var resetSection: some View {
        Section {
            Button("Ripristina Configurazione", role: .destructive) {
                showingResetAlert = true
            }
        } header: {
            Text("Reset")
        } footer: {
            Text("Questo rimuoverà tutti i provider personalizzati e le API key salvate, ripristinando la configurazione predefinita.")
        }
    }
}

// MARK: - Provider Settings Row
struct ProviderSettingsRow: View {
    let provider: AssistantProvider
    let hasValidAPIKey: Bool
    let onToggle: () -> Void
    let onConfigureAPIKey: () -> Void
    let onRemove: (() -> Void)?
    
    @State private var showingRemoveAlert = false
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: provider.icon)
                    .foregroundColor(provider.isActive ? .accentColor : .secondary)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(provider.name)
                            .font(.headline)
                        
                        if provider.type == .custom {
                            Text("CUSTOM")
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.2))
                                .foregroundColor(.blue)
                                .cornerRadius(4)
                        }
                    }
                    
                    Text(provider.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Toggle("", isOn: Binding(
                    get: { provider.isActive },
                    set: { _ in onToggle() }
                ))
                .labelsHidden()
            }
            
            if provider.isActive {
                HStack {
                    if provider.apiKeyRequired {
                        Button {
                            onConfigureAPIKey()
                        } label: {
                            HStack {
                                Image(systemName: hasValidAPIKey ? "checkmark.circle.fill" : "key")
                                    .foregroundColor(hasValidAPIKey ? .green : .orange)
                                Text(hasValidAPIKey ? "API Key Configurata" : "Configura API Key")
                            }
                        }
                        .font(.caption)
                        .buttonStyle(.bordered)
                    } else {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Nessuna API Key richiesta")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if let onRemove {
                        Button {
                            showingRemoveAlert = true
                        } label: {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Endpoint: \(provider.endpoint)")
                    Text("Modelli: \(provider.supportedModels.joined(separator: ", "))")
                    if let defaultModel = provider.defaultModel {
                        Text("Modello predefinito: \(defaultModel)")
                    }
                }
                .font(.caption2)
                .foregroundColor(.secondary)
                .padding(.top, 4)
            }
        }
        .padding(.vertical, 4)
        .alert("Rimuovi Provider", isPresented: $showingRemoveAlert) {
            Button("Annulla", role: .cancel) { }
            Button("Rimuovi", role: .destructive) {
                onRemove?()
            }
        } message: {
            Text("Sei sicuro di voler rimuovere il provider \"\(provider.name)\"? Questa azione non può essere annullata.")
        }
    }
}

// MARK: - WorkflowSettingsRow
struct WorkflowSettingsRow: View {
    let workflow: N8NWorkflow
    let workflowManager: N8NWorkflowManager
    let onEdit: () -> Void
    let onRemove: (() -> Void)?
    
    @State private var showingRemoveAlert = false
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(workflow.icon)
                    .font(.title2)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(workflow.name)
                            .font(.headline)
                        
                        Text(workflow.category.displayName)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.2))
                            .foregroundColor(.blue)
                            .cornerRadius(4)
                        
                        if !workflow.isDefault {
                            Text("CUSTOM")
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.2))
                                .foregroundColor(.orange)
                                .cornerRadius(4)
                        }
                    }
                    
                    Text(workflow.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Toggle("", isOn: Binding(
                    get: { workflow.isActive },
                    set: { _ in
                        workflowManager.toggleWorkflowStatus(workflow)
                    }
                ))
                .labelsHidden()
            }
            
            if workflow.isActive {
                HStack {
                    if workflow.requiresAuthentication {
                        HStack {
                            Image(systemName: "key")
                                .foregroundColor(.orange)
                            Text("Autenticazione richiesta")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    } else {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Nessuna autenticazione richiesta")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button {
                        onEdit()
                    } label: {
                        Image(systemName: "pencil")
                    }
                    .buttonStyle(.bordered)
                    
                    if let onRemove {
                        Button {
                            showingRemoveAlert = true
                        } label: {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Endpoint: \(workflow.endpoint)")
                    Text("Parametri: \(workflow.parameters.count)")
                    if !workflow.parameters.isEmpty {
                        Text("Parametri obbligatori: \(workflow.parameters.filter { $0.isRequired }.count)")
                    }
                }
                .font(.caption2)
                .foregroundColor(.secondary)
                .padding(.top, 4)
            }
        }
        .padding(.vertical, 4)
        .alert("Rimuovi Workflow", isPresented: $showingRemoveAlert) {
            Button("Annulla", role: .cancel) { }
            Button("Rimuovi", role: .destructive) {
                onRemove?()
            }
        } message: {
            Text("Sei sicuro di voler rimuovere il workflow \"\(workflow.name)\"? Questa azione non può essere annullata.")
        }
    }
}

// MARK: - Preview
#Preview {
    SettingsView(workflowManager: N8NWorkflowManager.shared)
}