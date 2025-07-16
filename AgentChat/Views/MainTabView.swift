//
//  MainTabView.swift
//  AgentChat
//
//  Created by Mario Moschetta on 04/07/25.
//

import SwiftUI

/// Vista principale con TabView che implementa le linee guida iOS 26
/// per la barra inferiore fluttuante con materiale Liquid Glass
struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: Chat
            ChatListView()
                .tabItem {
                    Label("Chat", systemImage: "bubble.left.and.bubble.right")
                }
                .tag(0)
            
            // Tab 2: Agenti
            AgentManagementView()
                .tabItem {
                    Label("Agenti", systemImage: "person.3.sequence")
                }
                .tag(1)
            
            // Tab 3: Servizio Posta (Placeholder)
            MailServiceView()
                .tabItem {
                    Label("Posta", systemImage: "envelope")
                }
                .tag(2)
            
            // Tab 4: Impostazioni
            SettingsView()
                .tabItem {
                    Label("Impostazioni", systemImage: "gear")
                }
                .tag(3)
        }
        .tint(.accentColor)
        // Implementa il comportamento di minimizzazione iOS 26
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarColorScheme(.automatic, for: .tabBar)
    }
}

// MARK: - Agent Management View
struct AgentManagementView: View {
    @StateObject private var agentManager = AgentManager.shared
    @StateObject private var configManager = AgentConfigurationManager.shared
    @State private var showingAddAgent = false
    @State private var showingGroupCreation = false
    @State private var selectedAgent: Agent?
    
    var body: some View {
        NavigationView {
            VStack {
                // Header con statistiche
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("I tuoi Agenti")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            Text("\(agentManager.agents.count) agenti configurati")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    // Quick stats
                    HStack(spacing: 20) {
                        StatCard(
                            title: "Attivi",
                            value: "\(agentManager.agents.filter { $0.isActive }.count)",
                            icon: "checkmark.circle.fill",
                            color: .green
                        )
                        
                        StatCard(
                            title: "Gruppi",
                            value: "\(agentManager.agentGroups.count)",
                            icon: "person.3.fill",
                            color: .blue
                        )
                        
                        StatCard(
                            title: "Workflow",
                            value: "\(configManager.configurations.count)",
                            icon: "flowchart.fill",
                            color: .purple
                        )
                    }
                    .padding(.horizontal)
                }
                .padding(.top)
                
                // Lista agenti
                List {
                    Section("Agenti Individuali") {
                        ForEach(agentManager.agents) { agent in
                            AgentRowView(agent: agent)
                                .onTapGesture {
                                    selectedAgent = agent
                                }
                        }
                        .onDelete(perform: deleteAgents)
                    }
                    
                    Section("Gruppi di Agenti") {
                        ForEach(agentManager.agentGroups) { group in
                            AgentGroupRowView(group: group)
                        }
                        .onDelete(perform: deleteGroups)
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
            .navigationBarHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button(action: { showingGroupCreation = true }) {
                            Image(systemName: "person.3.sequence.fill")
                        }
                        
                        Button(action: { showingAddAgent = true }) {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddAgent) {
                AddAgentView()
            }
            .sheet(isPresented: $showingGroupCreation) {
                GroupCreationView()
            }
            .sheet(item: $selectedAgent) { agent in
                AgentEditView(agent: agent)
            }
            
            // Vista di default quando nessun agente è selezionato
            AgentWelcomeView(showingAddAgent: $showingAddAgent)
        }
    }
    
    private func deleteAgents(offsets: IndexSet) {
        for index in offsets {
            let agent = agentManager.agents[index]
            agentManager.removeAgent(agent)
        }
    }
    
    private func deleteGroups(offsets: IndexSet) {
        for index in offsets {
            let group = agentManager.agentGroups[index]
            agentManager.removeGroup(group)
        }
    }
}

// MARK: - Mail Service View (Placeholder)
struct MailServiceView: View {
    @State private var isComingSoon = true
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Spacer()
                
                // Icona principale
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [.blue.opacity(0.1), .purple.opacity(0.1)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [.blue, .purple]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                
                VStack(spacing: 12) {
                    Text("Servizio Posta AI")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Gestione intelligente delle email con AI")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Text("Funzionalità in arrivo:")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .padding(.top, 8)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        FeatureRow(icon: "brain", text: "Classificazione automatica email")
                        FeatureRow(icon: "text.bubble", text: "Risposte generate da AI")
                        FeatureRow(icon: "folder.badge.plus", text: "Organizzazione intelligente")
                        FeatureRow(icon: "bell.badge", text: "Notifiche prioritarie")
                        FeatureRow(icon: "shield.checkered", text: "Filtro spam avanzato")
                    }
                    .padding(.horizontal, 20)
                }
                
                Spacer()
                
                // Pulsante Coming Soon
                Button(action: {}) {
                    HStack {
                        Image(systemName: "clock")
                        Text("Prossimamente")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue, .purple]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(25)
                }
                .disabled(true)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Servizio Posta")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Supporting Views
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct AgentRowView: View {
    let agent: Agent
    
    var body: some View {
        HStack {
            // Icona agente
            ZStack {
                Circle()
                    .fill(agent.isActive ? Color.green.opacity(0.2) : Color.gray.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: agent.type.iconName)
                    .foregroundColor(agent.isActive ? .green : .gray)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(agent.name)
                    .font(.headline)
                
                Text(agent.role)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text(agent.type.displayName)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.2))
                        .foregroundColor(.blue)
                        .cornerRadius(4)
                    
                    if agent.isActive {
                        Text("Attivo")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.2))
                            .foregroundColor(.green)
                            .cornerRadius(4)
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct AgentGroupRowView: View {
    let group: AgentGroup
    
    var body: some View {
        HStack {
            ZStack {
                Circle()
                    .fill(Color.purple.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: "person.3.fill")
                    .foregroundColor(.purple)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(group.name)
                    .font(.headline)
                
                Text("\(group.agents.count) agenti")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct AgentWelcomeView: View {
    @Binding var showingAddAgent: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("Gestione Agenti")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Crea e configura i tuoi agenti AI personalizzati")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: { showingAddAgent = true }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Crea il tuo primo agente")
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(25)
            }
        }
        .padding()
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 20)
                .foregroundColor(.accentColor)
            Text(text)
                .font(.subheadline)
            Spacer()
        }
    }
}

struct GroupCreationView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var groupName = ""
    @State private var selectedAgents: Set<Agent> = []
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Creazione Gruppo Agenti")
                    .font(.title2)
                    .padding()
                
                Text("Funzionalità in sviluppo")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Nuovo Gruppo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annulla") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    MainTabView()
        .environment(\.managedObjectContext, CoreDataPersistenceManager.shared.container.viewContext)
}