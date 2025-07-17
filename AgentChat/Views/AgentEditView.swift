//
//  AgentEditView.swift
//  AgentChat
//
//  Created by Mario Moschetta on 04/07/25.
//

import SwiftUI
import Foundation

// MARK: - Agent Edit View
struct AgentEditView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var configManager = AgentConfigurationManager.shared
    
    // Stato dell'agente
    @State private var name: String
    @State private var systemPrompt: String
    @State private var personality: String
    @State private var role: String
    @State private var icon: String
    @State private var preferredProvider: String
    @State private var temperature: Double
    @State private var maxTokens: Int
    @State private var isActive: Bool
    @State private var memoryEnabled: Bool
    @State private var contextWindow: Int
    
    // UI State
    @State private var showingIconPicker = false
    @State private var showingProviderPicker = false
    @State private var showingPreview = false
    @State private var isValid = true
    @State private var validationMessage = ""
    
    private let isEditing: Bool
    private let originalAgent: AgentConfiguration?
    private let onSave: ((AgentConfiguration) -> Void)?
    
    // Providers disponibili
    private let availableProviders = ["OpenAI", "Anthropic", "N8N", "Local"]
    
    // Icone predefinite
    private let availableIcons = [
        "🤖", "👨‍💻", "👩‍💻", "🧠", "💡", "🎯", "📝", "🔍", "📊", "🎨",
        "🔬", "📚", "💼", "🎭", "🌟", "⚡", "🚀", "🎪", "🎵", "🏆"
    ]
    
    init(agent: AgentConfiguration?, onSave: ((AgentConfiguration) -> Void)? = nil) {
        self.originalAgent = agent
        self.isEditing = agent != nil
        self.onSave = onSave
        
        if let agent = agent {
            _name = State(initialValue: agent.name)
            _systemPrompt = State(initialValue: agent.systemPrompt)
            _personality = State(initialValue: agent.personality)
            _role = State(initialValue: agent.role)
            _icon = State(initialValue: agent.icon)
            _preferredProvider = State(initialValue: agent.preferredProvider)
            _temperature = State(initialValue: agent.temperature)
            _maxTokens = State(initialValue: agent.maxTokens)
            _isActive = State(initialValue: agent.isActive)
            _memoryEnabled = State(initialValue: agent.memoryEnabled)
            _contextWindow = State(initialValue: agent.contextWindow)
        } else {
            _name = State(initialValue: "")
            _systemPrompt = State(initialValue: "")
            _personality = State(initialValue: "")
            _role = State(initialValue: "")
            _icon = State(initialValue: "🤖")
            _preferredProvider = State(initialValue: "OpenAI")
            _temperature = State(initialValue: 0.7)
            _maxTokens = State(initialValue: 2000)
            _isActive = State(initialValue: true)
            _memoryEnabled = State(initialValue: true)
            _contextWindow = State(initialValue: 4000)
        }
    }
    
    var body: some View {
        Form {
            basicInfoSection
            systemPromptSection
            technicalConfigSection
            featuresSection
            validationSection
        }
        .navigationTitle(isEditing ? "Modifica Agente" : "Nuovo Agente")
        .safeAreaInset(edge: .bottom) {
            HStack {
                Button("Annulla") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button(isEditing ? "Salva" : "Crea") {
                    saveAgent()
                }
                .disabled(name.isEmpty || preferredProvider.isEmpty)
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(Color(.systemBackground))
        }
        .sheet(isPresented: $showingIconPicker) {
            AgentIconPickerView(selectedIcon: $icon)
        }
        .sheet(isPresented: $showingProviderPicker) {
            ProviderPickerView(selectedProvider: $preferredProvider)
        }
        .sheet(isPresented: $showingPreview) {
            PromptPreviewView(systemPrompt: systemPrompt, agentName: name)
        }
        .onChange(of: name) { _, _ in validateForm() }
        .onChange(of: systemPrompt) { _, _ in validateForm() }
        .onChange(of: role) { _, _ in validateForm() }
        .onAppear {
            validateForm()
        }
    }
    
    private var basicInfoSection: some View {
        Section("Informazioni Base") {
            HStack {
                Button(action: { showingIconPicker = true }) {
                    Text(icon)
                        .font(.title)
                        .frame(width: 40, height: 40)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    TextField("Nome agente", text: $name)
                        .font(.headline)
                    
                    TextField("Ruolo (es. Assistente AI)", text: $role)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            TextField("Personalità", text: $personality)
                .lineLimit(2)
        }
    }
    
    private var systemPromptSection: some View {
        Section("System Prompt") {
            VStack(alignment: .leading, spacing: 8) {
                Text("Definisci come l'agente deve comportarsi e rispondere")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                TextField("System prompt...", text: $systemPrompt)
                    .lineLimit(6)
                
                HStack {
                    Button("Anteprima") {
                        showingPreview = true
                    }
                    .font(.caption)
                    
                    Spacer()
                    
                    Text("\(systemPrompt.count) caratteri")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private var technicalConfigSection: some View {
        Section("Configurazione Tecnica") {
            providerRow
            temperatureSlider
            maxTokensSlider
            contextWindowSlider
        }
    }
    
    private var providerRow: some View {
        HStack {
            Text("Provider")
            Spacer()
            Button(preferredProvider) {
                showingProviderPicker = true
            }
            .foregroundColor(.blue)
        }
    }
    
    private var temperatureSlider: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Creatività")
                Spacer()
                Text(String(format: "%.1f", temperature))
                    .foregroundColor(.secondary)
            }
            
            Slider(value: $temperature, in: 0...2, step: 0.1)
            
            HStack {
                Text("Preciso")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                Text("Creativo")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var maxTokensSlider: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Lunghezza Risposta")
                Spacer()
                Text("\(maxTokens) token")
                    .foregroundColor(.secondary)
            }
            
            Slider(value: Binding(
                get: { Double(maxTokens) },
                set: { maxTokens = Int($0) }
            ), in: 100...8000, step: 100)
        }
    }
    
    private var contextWindowSlider: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Finestra Contesto")
                Spacer()
                Text("\(contextWindow) token")
                    .foregroundColor(.secondary)
            }
            
            Slider(value: Binding(
                get: { Double(contextWindow) },
                set: { contextWindow = Int($0) }
            ), in: 1000...32000, step: 1000)
        }
    }
    
    private var featuresSection: some View {
        Section("Funzionalità") {
            Toggle("Agente Attivo", isOn: $isActive)
            
            VStack(alignment: .leading, spacing: 4) {
                Toggle("Memoria Conversazione", isOn: $memoryEnabled)
                
                if memoryEnabled {
                    Text("L'agente ricorderà il contesto delle conversazioni precedenti")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    @ViewBuilder
    private var validationSection: some View {
        if !isValid {
            Section {
                Text(validationMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
    }
    
    private func validateForm() {
        let tempAgent = AgentConfiguration(
            name: name,
            systemPrompt: systemPrompt,
            personality: personality,
            role: role,
            icon: icon,
            preferredProvider: preferredProvider,
            temperature: temperature,
            maxTokens: maxTokens,
            isActive: isActive,
            memoryEnabled: memoryEnabled,
            contextWindow: contextWindow
        )
        
        let validationErrors = configManager.validateAgentConfiguration(tempAgent)
        isValid = validationErrors.isEmpty
        validationMessage = validationErrors.first ?? ""
    }
    
    private func saveAgent() {
        let newAgent = AgentConfiguration(
            id: originalAgent?.id ?? UUID(),
            name: name,
            systemPrompt: systemPrompt,
            personality: personality,
            role: role,
            icon: icon,
            preferredProvider: preferredProvider,
            temperature: temperature,
            maxTokens: maxTokens,
            isActive: isActive,
            memoryEnabled: memoryEnabled,
            contextWindow: contextWindow
        )
        
        // Chiama la closure se fornita, altrimenti usa il manager standard
        if let onSave = onSave {
            onSave(newAgent)
        } else {
            if isEditing {
                configManager.updateAgent(newAgent)
            } else {
                configManager.addAgent(newAgent)
            }
        }
        
        dismiss()
    }
}

// MARK: - Agent Icon Picker View
struct AgentIconPickerView: View {
    @Binding var selectedIcon: String
    @Environment(\.dismiss) private var dismiss
    
    private let availableIcons = [
        "🤖", "👨‍💻", "👩‍💻", "🧠", "💡", "🎯", "📝", "🔍", "📊", "🎨",
        "🔬", "📚", "💼", "🎭", "🌟", "⚡", "🚀", "🎪", "🎵", "🏆"
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
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding()
            .navigationTitle("Scegli Icona")
        }
    }
}

// MARK: - Provider Picker View
struct ProviderPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedProvider: String
    
    private let providers = [
        ("OpenAI", "🔵", "GPT-4, GPT-3.5"),
        ("Anthropic", "🟠", "Claude 3"),
        ("N8N", "🟣", "Workflow Automation"),
        ("Local", "🟢", "Modelli Locali")
    ]
    
    var body: some View {
        NavigationView {
            List {
                ForEach(providers, id: \.0) { provider in
                    Button(action: {
                        selectedProvider = provider.0
                        dismiss()
                    }) {
                        HStack {
                            Text(provider.1)
                                .font(.title2)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(provider.0)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text(provider.2)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if selectedProvider == provider.0 {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Scegli Provider")
        }
    }
}

// MARK: - Prompt Preview View
struct PromptPreviewView: View {
    @Environment(\.dismiss) private var dismiss
    let systemPrompt: String
    let agentName: String
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Anteprima System Prompt")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Questo è come l'agente \"\(agentName)\" interpreterà le sue istruzioni:")
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    Text(systemPrompt.isEmpty ? "Nessun system prompt definito" : systemPrompt)
                        .font(.body)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Anteprima")
        }
    }
}

// MARK: - Preview
struct AgentEditView_Previews: PreviewProvider {
    static var previews: some View {
        AgentEditView(agent: nil as AgentConfiguration?)
    }
}