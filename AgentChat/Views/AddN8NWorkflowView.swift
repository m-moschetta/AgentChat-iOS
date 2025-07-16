//
//  AddN8NWorkflowView.swift
//  AgentChat
//
//  Created by Mario Moschetta on 04/07/25.
//

import SwiftUI
import Foundation

struct AddN8NWorkflowView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var workflowManager: N8NWorkflowManager
    
    @State private var name = ""
    @State private var endpoint = ""
    @State private var description = ""
    @State private var icon = "🔧"
    @State private var category: WorkflowCategory = .custom
    @State private var requiresAuthentication = false
    @State private var parameters: [N8NParameter] = []
    @State private var showingAddParameter = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isValidating = false
    
    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !endpoint.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        isValidURL(endpoint)
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Sezione Informazioni Workflow
                Section("Informazioni Workflow") {
                    HStack {
                        Text("Icona")
                        Spacer()
                        TextField("🔧", text: $icon)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 50)
                    }
                    
                    TextField("Nome workflow", text: $name)
                        .autocorrectionDisabled()
                    
                    TextField("Descrizione", text: $description)
                    
                    Picker("Categoria", selection: $category) {
                        ForEach(WorkflowCategory.allCases, id: \.self) { category in
                            Text(category.displayName).tag(category)
                        }
                    }
                }
                
                // Sezione Configurazione Endpoint
                Section("Configurazione Endpoint") {
                    TextField("URL Endpoint", text: $endpoint)
                        .autocorrectionDisabled()
                    
                    if !endpoint.isEmpty && !isValidURL(endpoint) {
                        Label("URL non valido", systemImage: "exclamationmark.triangle")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    
                    Toggle("Richiede Autenticazione", isOn: $requiresAuthentication)
                    
                    if requiresAuthentication {
                        Text("L'API key verrà richiesta al primo utilizzo del workflow")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Sezione Parametri Input
                Section {
                    ForEach(parameters) { parameter in
                        ParameterRowView(parameter: parameter)
                    }
                    .onDelete(perform: deleteParameter)
                    
                    Button(action: {
                        showingAddParameter = true
                    }) {
                        Label("Aggiungi Parametro", systemImage: "plus.circle")
                    }
                } header: {
                    Text("Parametri Input")
                } footer: {
                    if parameters.isEmpty {
                        Text("Aggiungi parametri che l'utente dovrà compilare per utilizzare questo workflow")
                            .font(.caption)
                    }
                }
                
                // Sezione Test Connessione
                if isFormValid {
                    Section {
                        Button(action: testConnection) {
                            HStack {
                                if isValidating {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "network")
                                }
                                Text("Testa Connessione")
                            }
                        }
                        .disabled(isValidating)
                    } footer: {
                        Text("Verifica che l'endpoint sia raggiungibile prima di salvare")
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Nuovo Workflow")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salva") {
                        saveWorkflow()
                    }
                    .disabled(!isFormValid)
                }
            }
        }
        .sheet(isPresented: $showingAddParameter) {
            AddParameterView { parameter in
                parameters.append(parameter)
            }
        }
        .alert("Errore", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    // MARK: - Private Methods
    
    private func deleteParameter(at offsets: IndexSet) {
        parameters.remove(atOffsets: offsets)
    }
    
    private func isValidURL(_ urlString: String) -> Bool {
        guard let url = URL(string: urlString) else { return false }
        return url.scheme != nil && url.host != nil
    }
    
    private func testConnection() {
        isValidating = true
        
        let testWorkflow = N8NWorkflow(
            id: UUID().uuidString,
            name: name,
            endpoint: endpoint,
            description: description,
            icon: icon,
            parameters: parameters,
            requiresAuthentication: requiresAuthentication,
            isActive: true,
            category: category,
            isDefault: false
        )
        
        Task {
            do {
                let isValid = try await N8NService.shared.validateConnection(for: testWorkflow)
                await MainActor.run {
                    isValidating = false
                    if isValid {
                        alertMessage = "✅ Connessione riuscita! Il workflow è pronto per essere salvato."
                    } else {
                        alertMessage = "⚠️ Connessione riuscita ma il workflow potrebbe non funzionare correttamente."
                    }
                    showingAlert = true
                }
            } catch {
                await MainActor.run {
                    isValidating = false
                    alertMessage = "❌ Errore di connessione: \(error.localizedDescription)"
                    showingAlert = true
                }
            }
        }
    }
    
    private func saveWorkflow() {
        let workflow = N8NWorkflow(
            id: UUID().uuidString,
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            endpoint: endpoint.trimmingCharacters(in: .whitespacesAndNewlines),
            description: description.trimmingCharacters(in: .whitespacesAndNewlines),
            icon: icon.isEmpty ? "🔧" : icon,
            parameters: parameters,
            requiresAuthentication: requiresAuthentication,
            isActive: true,
            category: category,
            isDefault: false
        )
        
        do {
            try workflowManager.addCustomWorkflow(workflow)
            dismiss()
        } catch {
            alertMessage = "Errore nel salvare il workflow: \(error.localizedDescription)"
            showingAlert = true
        }
    }
}

// MARK: - Parameter Row View
struct ParameterRowView: View {
    let parameter: N8NParameter
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(parameter.name)
                    .font(.headline)
                
                Spacer()
                
                if parameter.isRequired {
                    Text("Obbligatorio")
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.red.opacity(0.1))
                        .foregroundColor(.red)
                        .cornerRadius(4)
                }
                
                Text(parameter.type.displayName)
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(4)
            }
            
            if !parameter.description.isEmpty {
                Text(parameter.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if !parameter.placeholder.isEmpty {
                Text("Placeholder: \(parameter.placeholder)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Extensions (moved to N8NWorkflow.swift)

// MARK: - Preview
#Preview {
    AddN8NWorkflowView(workflowManager: N8NWorkflowManager.shared)
}