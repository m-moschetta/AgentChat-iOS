//
//  SettingsView.swift
//  AgentChat
//
//  Created by Mario Moschetta on 04/07/25.
//

import SwiftUI
import UniformTypeIdentifiers

// MARK: - Settings View
struct SettingsView: View {
    @StateObject private var configuration = LocalAssistantConfiguration()
    @StateObject private var agentManager = AgentManager.shared
    @StateObject private var configManager = AgentConfigurationManager.shared
    @State private var showingAPIKeyConfig = false
    @State private var selectedProvider: AssistantProvider?
    @State private var showingAgentConfiguration = false
    @State private var showingCustomProvider = false
    @State private var showingImportExport = false
    
    var body: some View {
        NavigationView {
            List {
                // MARK: - Providers Section
                Section("Providers") {
                    ForEach(configuration.availableProviders, id: \.id) { provider in
                        ProviderSettingsRow(
                            provider: provider,
                            hasValidAPIKey: configuration.hasValidAPIKey(for: provider),
                            onConfigureTapped: {
                                selectedProvider = provider
                                showingAPIKeyConfig = true
                            }
                        )
                    }
                    
                    Button("Add Custom Provider") {
                        showingCustomProvider = true
                    }
                    .foregroundColor(.blue)
                }
                
                // MARK: - Agents Section
                Section("Agents") {
                    NavigationLink("Configure Agents") {
                        AgentConfigurationView()
                    }
                    
                    NavigationLink("Manage Legacy Agents") {
                        LegacyAgentListView()
                    }
                }
                
                // MARK: - Data Management Section
                Section("Data Management") {
                    Button("Import/Export Settings") {
                        showingImportExport = true
                    }
                    
                    Button("Reset All Settings") {
                        resetAllSettings()
                    }
                    .foregroundColor(.red)
                }
                
                // MARK: - App Info Section
                Section("App Information") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Build")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingAPIKeyConfig) {
                if let provider = selectedProvider {
                    APIKeyConfigView(provider: provider)
                }
            }
            .sheet(isPresented: $showingCustomProvider) {
                CustomProviderView()
            }
            .sheet(isPresented: $showingImportExport) {
                ImportExportView()
            }
        }
    }
    
    private func resetAllSettings() {
        // Reset all configurations
        configuration.resetToDefaults()
        configManager.resetToDefaults()
        agentManager.resetToDefaults()
    }
}

// MARK: - Provider Settings Row
struct ProviderSettingsRow: View {
    let provider: AssistantProvider
    let hasValidAPIKey: Bool
    let onConfigureTapped: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: provider.icon)
                .font(.title2)
                .frame(width: 40, height: 40)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            
            VStack(alignment: .leading) {
                Text(provider.name)
                    .font(.headline)
                
                Text(hasValidAPIKey ? "Configured" : "Not configured")
                    .font(.caption)
                    .foregroundColor(hasValidAPIKey ? .green : .orange)
            }
            
            Spacer()
            
            Button("Configure") {
                onConfigureTapped()
            }
            .buttonStyle(.bordered)
        }
    }
}

// MARK: - Legacy Agent List View
struct LegacyAgentListView: View {
    @StateObject private var agentManager = AgentManager.shared
    @State private var showingAddAgent = false
    
    var body: some View {
        List {
            ForEach(agentManager.agents) { agent in
                HStack {
                    Text(agent.avatar)
                        .font(.title2)
                    
                    VStack(alignment: .leading) {
                        Text(agent.name)
                            .font(.headline)
                        Text(agent.provider.name)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if agent.isActive {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                }
            }
            .onDelete(perform: deleteAgents)
        }
        .navigationTitle("Legacy Agents")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Add") {
                    showingAddAgent = true
                }
            }
        }
        .sheet(isPresented: $showingAddAgent) {
            AddAgentView(agentManager: agentManager)
        }
    }
    
    private func deleteAgents(offsets: IndexSet) {
        for index in offsets {
            let agent = agentManager.agents[index]
            agentManager.removeAgent(agent)
        }
    }
}

// MARK: - Import Export View
struct ImportExportView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var configManager = AgentConfigurationManager.shared
    @State private var showingDocumentPicker = false
    @State private var showingShareSheet = false
    @State private var exportURL: URL?
    
    var body: some View {
        NavigationView {
            List {
                Section("Export") {
                    Button("Export Agent Configurations") {
                        exportConfigurations()
                    }
                    
                    Button("Export All Settings") {
                        exportAllSettings()
                    }
                }
                
                Section("Import") {
                    Button("Import Configurations") {
                        showingDocumentPicker = true
                    }
                }
            }
            .navigationTitle("Import/Export")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            if let url = exportURL {
                ShareSheet(activityItems: [url])
            }
        }
        .fileImporter(
            isPresented: $showingDocumentPicker,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            handleImport(result: result)
        }
    }
    
    private func exportConfigurations() {
        // TODO: Implement export functionality
        // if let url = configManager.exportConfigurations() {
        //     exportURL = url
        //     showingShareSheet = true
        // }
    }
    
    private func exportAllSettings() {
        // Implementation for exporting all settings
        // This would include agent configurations, API keys (encrypted), etc.
    }
    
    private func handleImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            if let url = urls.first {
                // TODO: Implement import functionality
                // configManager.importConfigurations(from: url)
            }
        case .failure(let error):
            print("Import failed: \(error)")
        }
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No updates needed
    }
}

// MARK: - Preview
#Preview {
    SettingsView()
}