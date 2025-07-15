//
//  CustomProviderView.swift
//  AgentChat
//
//  Created by Mario Moschetta on 04/07/25.
//

import SwiftUI

// MARK: - Custom Provider View
struct CustomProviderView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var configuration = LocalAssistantConfiguration()
    
    @State private var name = ""
    @State private var endpoint = ""
    @State private var selectedType: ProviderType = .custom
    @State private var apiKeyRequired = true
    @State private var models = ""
    @State private var defaultModel = ""
    @State private var selectedIcon = "brain.head.profile"
    @State private var description = ""
    
    @State private var showingValidationAlert = false
    @State private var validationErrors: [String] = []
    @State private var showingSuccessAlert = false
    
    private let availableIcons = [
        "brain.head.profile", "sparkles", "wind", "magnifyingglass.circle",
        "doc.text", "cpu", "network", "server.rack", "cloud", "gear",
        "bolt", "star", "heart", "eye", "hand.raised", "message",
        "bubble.left", "bubble.right", "quote.bubble", "text.bubble"
    ]
    
    var modelsList: [String] {
        models.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Nome del provider", text: $name)
                    
                    Picker("Tipo", selection: $selectedType) {
                        ForEach(ProviderType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    
                    TextField("Endpoint API", text: $endpoint)
                        .autocorrectionDisabled()
                    
                    Toggle("Richiede API Key", isOn: $apiKeyRequired)
                } header: {
                    Text("Informazioni Base")
                } footer: {
                    Text("Inserisci l'URL completo dell'endpoint API (es. https://api.example.com/v1/chat/completions)")
                }
                
                Section {
                    TextField("Modelli supportati", text: $models)
                        .lineLimit(6)
                    
                    if !modelsList.isEmpty {
                        Picker("Modello predefinito", selection: $defaultModel) {
                            Text("Nessuno").tag("")
                            ForEach(modelsList, id: \.self) { model in
                                Text(model).tag(model)
                            }
                        }
                    }
                } header: {
                    Text("Modelli")
                } footer: {
                    Text("Inserisci i modelli separati da virgola (es. gpt-4, gpt-3.5-turbo, claude-3)")
                }
                
                Section {
                    HStack {
                        Text("Icona")
                        Spacer()
                        Menu {
                            ForEach(availableIcons, id: \.self) { icon in
                                Button {
                                    selectedIcon = icon
                                } label: {
                                    Label(icon, systemImage: icon)
                                }
                            }
                        } label: {
                            HStack {
                                Image(systemName: selectedIcon)
                                    .foregroundColor(.accentColor)
                                Text(selectedIcon)
                                    .foregroundColor(.secondary)
                                Image(systemName: "chevron.up.chevron.down")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                        }
                    }
                    
                    TextField("Descrizione", text: $description)
                        .lineLimit(4)
                } header: {
                    Text("Personalizzazione")
                }
                
                if !name.isEmpty && !endpoint.isEmpty && !modelsList.isEmpty {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: selectedIcon)
                                    .foregroundColor(.accentColor)
                                    .frame(width: 24)
                                Text(name)
                                    .font(.headline)
                            }
                            
                            Text(description.isEmpty ? "Nessuna descrizione" : description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("Endpoint: \(endpoint)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("Modelli: \(modelsList.joined(separator: ", "))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            if apiKeyRequired {
                                Label("Richiede API Key", systemImage: "key")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }
                        .padding(.vertical, 4)
                    } header: {
                        Text("Anteprima")
                    }
                }
            }
            .navigationTitle("Nuovo Provider")
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    Button("Annulla") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button("Salva") {
                        saveProvider()
                    }
                    .disabled(!isFormValid)
                }
            }
            .alert("Errori di Validazione", isPresented: $showingValidationAlert) {
                Button("OK") { }
            } message: {
                Text(validationErrors.joined(separator: "\n"))
            }
            .alert("Provider Aggiunto", isPresented: $showingSuccessAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Il provider personalizzato è stato aggiunto con successo.")
            }
        }
    }
    
    // MARK: - Computed Properties
    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !endpoint.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !modelsList.isEmpty
    }
    
    // MARK: - Methods
    private func saveProvider() {
        let provider = AssistantProvider(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            type: selectedType,
            endpoint: endpoint.trimmingCharacters(in: .whitespacesAndNewlines),
            apiKeyRequired: apiKeyRequired,
            supportedModels: modelsList,
            defaultModel: defaultModel.isEmpty ? nil : defaultModel,
            icon: selectedIcon,
            description: description.trimmingCharacters(in: .whitespacesAndNewlines),
            isActive: true
        )
        
        let errors = configuration.validateProvider(provider)
        
        if !errors.isEmpty {
            validationErrors = errors
            showingValidationAlert = true
            return
        }
        
        configuration.addCustomProvider(provider)
        showingSuccessAlert = true
    }
}

// MARK: - Preview
#Preview {
    CustomProviderView()
}