//
//  AgentConfigurationView.swift
//  AgentChat
//
//  Created by Mario Moschetta on 04/07/25.
//

import SwiftUI
import UniformTypeIdentifiers

// MARK: - Agent Configuration View
struct AgentConfigurationView: View {
    @StateObject private var configManager = AgentConfigurationManager.shared
    @State private var showingAddAgent = false
    @State private var showingImportExport = false
    @State private var searchText = ""
    
    var filteredAgents: [AgentConfiguration] {
        if searchText.isEmpty {
            return configManager.agents
        } else {
            return configManager.agents.filter { agent in
                agent.name.localizedCaseInsensitiveContains(searchText) ||
                agent.role.localizedCaseInsensitiveContains(searchText) ||
                agent.preferredProvider.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Statistiche rapide
                AgentStatisticsView()
                    .padding(.horizontal)
                
                // Lista agenti
                List {
                    ForEach(filteredAgents) { agent in
                        NavigationLink(destination: AgentEditView(agent: agent)) {
                            AgentRow(agent: agent, isSelected: false, onTap: {})
                        }
                    }
                    .onDelete(perform: deleteAgents)
                }
                .searchable(text: $searchText, prompt: "Cerca agenti...")
            }
            .navigationTitle("Configurazione Agenti")
            .toolbar(content: {
                ToolbarItem(placement: .navigation) {
                    Menu {
                        Button("Importa/Esporta") {
                            showingImportExport = true
                        }
                        
                        Button("Ripristina Default") {
                            resetToDefaults()
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button("Aggiungi") {
                        showingAddAgent = true
                    }
                }
            })
            .sheet(isPresented: $showingAddAgent) {
                AgentEditView(agent: nil)
            }
            .sheet(isPresented: $showingImportExport) {
                AgentImportExportView()
            }
        }
    }
    
    private func deleteAgents(offsets: IndexSet) {
        for index in offsets {
            let agent = filteredAgents[index]
            configManager.deleteAgent(agent)
        }
    }
    
    private func resetToDefaults() {
        configManager.resetToDefaults()
    }
}

// MARK: - Agent Statistics View
struct AgentStatisticsView: View {
    @StateObject private var configManager = AgentConfigurationManager.shared
    
    var statistics: (total: Int, active: Int, byProvider: [String: Int]) {
        return configManager.getAgentStatistics()
    }
    
    var body: some View {
        HStack {
            StatCard(title: "Totale", value: "\(statistics.total)", color: .blue)
            StatCard(title: "Attivi", value: "\(statistics.active)", color: .green)
            StatCard(title: "Provider", value: "\(statistics.byProvider.count)", color: .orange)
        }
        .padding(.vertical, 8)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Agent Import Export View
struct AgentImportExportView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var configManager = AgentConfigurationManager.shared
    @State private var showingDocumentPicker = false
    @State private var showingShareSheet = false
    @State private var exportData: Data?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Gestione Configurazioni")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Esporta le tue configurazioni di agenti per condividerle o farne un backup, oppure importa configurazioni da altri dispositivi.")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 12) {
                    Button(action: exportAgents) {
                        Label("Esporta Configurazioni", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button(action: { showingDocumentPicker = true }) {
                        Label("Importa Configurazioni", systemImage: "square.and.arrow.down")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Importa/Esporta")
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    Button("Chiudi") {
                        dismiss()
                    }
                }
            }
        }
        .fileImporter(
            isPresented: $showingDocumentPicker,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            handleImport(result)
        }
        .sheet(isPresented: $showingShareSheet) {
            if let data = exportData {
                ShareSheet(activityItems: [data])
            }
        }
    }
    
    private func exportAgents() {
        if let data = configManager.exportAgents() {
            exportData = data
            showingShareSheet = true
        }
    }
    
    private func handleImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            do {
                let data = try Data(contentsOf: url)
                if configManager.importAgents(from: data) {
                    // Successo - mostra alert o toast
                }
            } catch {
                // Errore - mostra alert
            }
            
        case .failure(let error):
            print("Errore nell'importazione: \(error)")
        }
    }
}

// ShareSheet is defined in SettingsView.swift

// MARK: - Preview
struct AgentConfigurationView_Previews: PreviewProvider {
    static var previews: some View {
        AgentConfigurationView()
    }
}