//
//  GroupSelectionView.swift
//  AgentChat
//
//  Created by Mario Moschetta on 04/07/25.
//

import SwiftUI

// MARK: - GroupSelectionView
struct GroupSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTemplate: AgentGroupTemplate?
    @State private var showingCustomGroupBuilder = false
    @State private var searchText = ""
    
    let onGroupSelected: (AgentGroupTemplate) -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header con ricerca
                VStack(spacing: 16) {
                    Text("Scegli un Team di Agenti")
                        .font(.title2)
                        .font(.system(size: 17, weight: .bold))
                        .multilineTextAlignment(.center)
                    
                    Text("Seleziona un team predefinito o crea il tuo gruppo personalizzato")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    // Barra di ricerca
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        
                        TextField("Cerca template...", text: $searchText)
                            .textFieldStyle(.plain)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.gray.opacity(0.1))
                    .cornerRadius(10)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(.ultraThinMaterial)
                
                Divider()
                
                // Lista template
                ScrollView {
                    LazyVStack(spacing: 16) {
                        // Template predefiniti
                        ForEach(filteredTemplates, id: \.name) { template in
                            GroupTemplateCard(
                                template: template,
                                isSelected: selectedTemplate?.name == template.name,
                                onTap: {
                                    selectedTemplate = template
                                }
                            )
                        }
                        
                        // Opzione per creare gruppo personalizzato
                        CustomGroupCard {
                            showingCustomGroupBuilder = true
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
                
                // Pulsante di conferma
                if selectedTemplate != nil {
                    VStack(spacing: 0) {
                        Divider()
                        
                        Button(action: {
                            if let template = selectedTemplate {
                                onGroupSelected(template)
                                dismiss()
                            }
                        }) {
                            HStack {
                                Image(systemName: "arrow.right.circle.fill")
                                Text("Crea Gruppo")
                                    .font(.system(size: 17, weight: .medium))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(.ultraThinMaterial)
                    }
                }
            }

        }
        .sheet(isPresented: $showingCustomGroupBuilder) {
            CustomGroupBuilderView { customTemplate in
                onGroupSelected(customTemplate)
                dismiss()
            }
        }
    }
    
    private var filteredTemplates: [AgentGroupTemplate] {
        if searchText.isEmpty {
            return AgentGroupTemplate.allTemplates
        } else {
            return AgentGroupTemplate.allTemplates.filter { template in
                template.name.localizedCaseInsensitiveContains(searchText) ||
                template.description.localizedCaseInsensitiveContains(searchText) ||
                template.useCases.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
    }
}

// MARK: - GroupTemplateCard
struct GroupTemplateCard: View {
    let template: AgentGroupTemplate
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header con icona e nome
                HStack {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(
                                colors: gradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 50, height: 50)
                        
                        Text(template.icon)
                            .font(.title2)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(template.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("\(template.participants.count) agenti")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.blue)
                            .font(.title2)
                    }
                }
                
                // Descrizione
                Text(template.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
                
                // Partecipanti preview
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(template.participants.prefix(4), id: \.name) { agent in
                            AgentPreviewChip(agent: agent)
                        }
                        
                        if template.participants.count > 4 {
                            Text("+\(template.participants.count - 4)")
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.gray.opacity(0.2))
                                .cornerRadius(8)
                        }
                    }
                }
                
                // Casi d'uso
                if !template.useCases.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Ideale per:")
                            .font(.caption)
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Text(template.useCases.prefix(2).joined(separator: ", "))
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? .blue : .clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    private var gradientColors: [Color] {
        switch template.name {
        case "Product Team":
            return [.blue.opacity(0.8), .purple.opacity(0.8)]
        case "Brainstorming Squad":
            return [.purple.opacity(0.8), .pink.opacity(0.8)]
        case "Code Review Panel":
            return [.green.opacity(0.8), .mint.opacity(0.8)]
        case "Business Analysis Team":
            return [.orange.opacity(0.8), .yellow.opacity(0.8)]
        case "Design Thinking Team":
            return [.pink.opacity(0.8), .red.opacity(0.8)]
        case "Security Audit Team":
            return [.red.opacity(0.8), .orange.opacity(0.8)]
        default:
            return [.gray.opacity(0.8), .secondary.opacity(0.8)]
        }
    }
}

// MARK: - AgentPreviewChip
struct AgentPreviewChip: View {
    let agent: GroupAgent
    
    var body: some View {
        HStack(spacing: 4) {
            Text(agent.icon)
                .font(.caption2)
            
            Text(agent.name.components(separatedBy: " ").first ?? agent.name)
                .font(.caption2)
                .font(.system(size: 17, weight: .medium))
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(.gray.opacity(0.1))
        .cornerRadius(6)
    }
}

// MARK: - CustomGroupCard
struct CustomGroupCard: View {
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [.gray.opacity(0.3), .gray.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: "plus.circle.fill")
                        .font(.title)
                        .foregroundColor(.blue)
                }
                
                VStack(spacing: 8) {
                    Text("Crea Gruppo Personalizzato")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Scegli i tuoi agenti e personalizza il team")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                HStack {
                    Image(systemName: "wand.and.stars")
                    Text("Personalizza")
                        .font(.system(size: 17, weight: .medium))
                }
                .font(.caption)
                .foregroundColor(.blue)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.blue.opacity(0.1))
                .cornerRadius(8)
            }
            .frame(maxWidth: .infinity)
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.blue.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - CustomGroupBuilderView
struct CustomGroupBuilderView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var groupName = ""
    @State private var groupDescription = ""
    @State private var selectedIcon = "👥"
    @State private var selectedAgents: Set<String> = []
    @State private var showingIconPicker = false
    
    let onGroupCreated: (AgentGroupTemplate) -> Void
    
    private let availableIcons = ["👥", "🚀", "💡", "🔍", "⚙️", "🎯", "🎨", "📊", "🛡️", "🌟"]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Informazioni Gruppo") {
                    HStack {
                        Button(action: {
                            showingIconPicker = true
                        }) {
                            ZStack {
                                Circle()
                                    .fill(.blue.opacity(0.1))
                                    .frame(width: 50, height: 50)
                                
                                Text(selectedIcon)
                                    .font(.title2)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            TextField("Nome del gruppo", text: $groupName)
                                .font(.headline)
                            
                            TextField("Descrizione", text: $groupDescription)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section("Seleziona Agenti (\(selectedAgents.count))") {
                    ForEach(GroupAgent.allAgents, id: \.name) { agent in
                        AgentSelectionRow(
                            agent: agent,
                            isSelected: selectedAgents.contains(agent.name)
                        ) { isSelected in
                            if isSelected {
                                selectedAgents.insert(agent.name)
                            } else {
                                selectedAgents.remove(agent.name)
                            }
                        }
                    }
                }
                
                if !selectedAgents.isEmpty {
                    Section("Anteprima") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Il tuo gruppo includerà:")
                                .font(.headline)
                            
                            ForEach(selectedAgentsList, id: \.name) { agent in
                                HStack {
                                    Text(agent.icon)
                                    Text(agent.name)
                                        .font(.system(size: 17, weight: .medium))
                                    Text("- \(agent.role)")
                                        .foregroundColor(.secondary)
                                    Spacer()
                                }
                                .font(.caption)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Nuovo Gruppo")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Crea") {
                        createCustomGroup()
                    }
                    .disabled(!canCreateGroup)
                }
            }
        }
        .sheet(isPresented: $showingIconPicker) {
            IconPickerView(selectedIcon: $selectedIcon)
        }
    }
    
    private var selectedAgentsList: [GroupAgent] {
        return GroupAgent.allAgents.filter { selectedAgents.contains($0.name) }
    }
    
    private var canCreateGroup: Bool {
        !groupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        selectedAgents.count >= 2
    }
    
    private func createCustomGroup() {
        let customTemplate = AgentGroupTemplate(
            name: groupName,
            description: groupDescription.isEmpty ? "Gruppo personalizzato" : groupDescription,
            icon: selectedIcon,
            participants: selectedAgentsList,
            agentType: .group,
            useCases: ["Discussioni personalizzate", "Collaborazione su misura"]
        )
        
        onGroupCreated(customTemplate)
    }
}

// MARK: - AgentSelectionRow
struct AgentSelectionRow: View {
    let agent: GroupAgent
    let isSelected: Bool
    let onToggle: (Bool) -> Void
    
    var body: some View {
        HStack {
            Button(action: {
                onToggle(!isSelected)
            }) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(isSelected ? .blue : .gray.opacity(0.2))
                            .frame(width: 20, height: 20)
                        
                        if isSelected {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    
                    Text(agent.icon)
                        .font(.title3)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(agent.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(agent.role)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text(agent.personality)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                }
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - IconPickerView
struct IconPickerView: View {
    @Binding var selectedIcon: String
    @Environment(\.dismiss) private var dismiss
    
    private let availableIcons = [
        "👥", "🚀", "💡", "🔍", "⚙️", "🎯", "🎨", "📊", "🛡️", "🌟",
        "💼", "🎪", "🏆", "🔬", "🎭", "🎲", "🎸", "🎬", "📚", "🔮"
    ]
    
    var body: some View {
        NavigationView {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 20) {
                ForEach(availableIcons, id: \.self) { icon in
                    Button(action: {
                        selectedIcon = icon
                        dismiss()
                    }) {
                        ZStack {
                            Circle()
                                .fill(selectedIcon == icon ? .blue.opacity(0.2) : .gray.opacity(0.1))
                                .frame(width: 60, height: 60)
                            
                            Text(icon)
                                .font(.title)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
            .navigationTitle("Scegli Icona")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Chiudi") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    GroupSelectionView { template in
        print("Selected template: \(template.name)")
    }
}