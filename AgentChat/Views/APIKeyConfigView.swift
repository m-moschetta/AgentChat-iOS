//
//  APIKeyConfigView.swift
//  AgentChat
//
//  Created by Mario Moschetta on 04/07/25.
//

import SwiftUI
import Foundation

// MARK: - API Key Config View
struct APIKeyConfigView: View {
    let provider: AssistantProvider
    @Environment(\.dismiss) private var dismiss
    @StateObject private var configuration = LocalAssistantConfiguration()
    
    @State private var apiKey = ""
    @State private var isSecureEntry = true
    @State private var isTestingConnection = false
    @State private var testResult: TestResult?
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    enum TestResult {
        case success
        case failure(String)
    }
    
    // MARK: - Helper Methods
    private func isValidAPIKeyFormat(_ key: String, for providerType: ProviderType) -> Bool {
        switch providerType {
        case .openai:
            // OpenAI keys start with "sk-" and are typically 51 characters
            return key.hasPrefix("sk-") && key.count >= 20
        case .anthropic:
            // Anthropic keys start with "sk-ant-" 
            return key.hasPrefix("sk-ant-") && key.count >= 20
        case .mistral:
            // Mistral keys are typically long alphanumeric strings
            return key.count >= 20 && key.allSatisfy { $0.isLetter || $0.isNumber || $0 == "-" || $0 == "_" }
        case .perplexity:
            // Perplexity keys start with "pplx-"
            return key.hasPrefix("pplx-") && key.count >= 20
        case .grok:
            // Grok keys are typically long alphanumeric strings
            return key.count >= 20 && key.allSatisfy { $0.isLetter || $0.isNumber || $0 == "-" || $0 == "_" }
        case .deepSeek:
            // DeepSeek keys are typically long alphanumeric strings
            return key.count >= 20 && key.allSatisfy { $0.isLetter || $0.isNumber || $0 == "-" || $0 == "_" }
        case .n8n, .custom:
            // For N8N and custom providers, accept any non-empty string
            return !key.isEmpty
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: provider.icon)
                                .foregroundColor(.accentColor)
                                .frame(width: 24)
                            Text(provider.name)
                                .font(.headline)
                        }
                        
                        Text(provider.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Provider")
                }
                
                Section {
                    HStack {
                        if isSecureEntry {
                            SecureField("Inserisci la tua API key", text: $apiKey)
                        } else {
                            TextField("Inserisci la tua API key", text: $apiKey)
                        }
                        
                        Button {
                            isSecureEntry.toggle()
                        } label: {
                            Image(systemName: isSecureEntry ? "eye" : "eye.slash")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if !apiKey.isEmpty {
                        Button {
                            Task { await testConnection() }
                        } label: {
                            HStack {
                                if isTestingConnection {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "network")
                                }
                                Text(isTestingConnection ? "Test in corso..." : "Testa connessione")
                            }
                        }
                        .disabled(isTestingConnection || apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    
                    if let testResult {
                        switch testResult {
                        case .success:
                            Label("Connessione riuscita", systemImage: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        case .failure(let error):
                            Label("Test fallito", systemImage: "xmark.circle.fill")
                                .foregroundColor(.red)
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("API Key")
                } footer: {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("La tua API key verrà salvata in modo sicuro nel Keychain del dispositivo.")
                        
                        if provider.type == .openai {
                            Text("Ottieni la tua API key da: platform.openai.com")
                        } else if provider.type == .anthropic {
                            Text("Ottieni la tua API key da: console.anthropic.com")
                        } else if provider.type == .mistral {
                            Text("Ottieni la tua API key da: console.mistral.ai")
                        } else if provider.type == .perplexity {
                            Text("Ottieni la tua API key da: perplexity.ai")
                        } else if provider.type == .grok {
                            Text("Ottieni la tua API key da: console.x.ai")
                        } else if provider.type == .deepSeek {
                            Text("Ottieni la tua API key da: platform.deepseek.com")
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                
                if configuration.hasValidAPIKey(for: provider) {
                    Section {
                        Button("Rimuovi API Key", role: .destructive) {
                            removeAPIKey()
                        }
                    }
                }
            }
            .navigationTitle("Configura API Key")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salva") {
                        saveAPIKey()
                    }
                    .disabled(apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .alert("Configurazione API Key", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
        .onAppear {
            loadExistingAPIKey()
        }
    }
    
    // MARK: - Methods
    private func loadExistingAPIKey() {
        if let existingKey = configuration.getAPIKey(for: provider) {
            // Show only first and last 4 characters for security
            if existingKey.count > 8 {
                let start = existingKey.prefix(4)
                let end = existingKey.suffix(4)
                apiKey = "\(start)...\(end)"
            } else {
                apiKey = String(repeating: "*", count: existingKey.count)
            }
        }
    }
    
    private func saveAPIKey() {
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedKey.isEmpty else {
            alertMessage = "Inserisci una API key valida"
            showingAlert = true
            return
        }
        
        // Validate API key format based on provider type
        if !isValidAPIKeyFormat(trimmedKey, for: provider.type) {
            alertMessage = "Formato API key non valido per \(provider.name)"
            showingAlert = true
            return
        }
        
        // Don't save if it's the masked version
        if trimmedKey.contains("...") || trimmedKey.contains("*") {
            alertMessage = "API key già configurata. Per modificarla, rimuovi prima quella esistente."
            showingAlert = true
            return
        }
        
        // Save the API key
        let success = configuration.setAPIKey(trimmedKey, for: provider)
        
        if success {
            // Verify the key was actually saved
            if let savedKey = configuration.getAPIKey(for: provider), !savedKey.isEmpty {
                alertMessage = "API key salvata con successo"
                showingAlert = true
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    dismiss()
                }
            } else {
                alertMessage = "Errore: API key non salvata correttamente nel Keychain"
                showingAlert = true
            }
        } else {
            alertMessage = "Errore nel salvare l'API key nel Keychain. Verifica i permessi dell'app."
            showingAlert = true
        }
    }
    
    private func removeAPIKey() {
        if configuration.removeAPIKey(for: provider) {
            apiKey = ""
            testResult = nil
            alertMessage = "API key rimossa con successo"
            showingAlert = true
        } else {
            alertMessage = "Errore nella rimozione dell'API key"
            showingAlert = true
        }
    }
    
    private func testConnection() async {
        guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        // Don't test if it's the masked version
        if apiKey.contains("...") || apiKey.contains("*") {
            testResult = .failure("Inserisci la API key completa per testare la connessione")
            return
        }
        
        isTestingConnection = true
        testResult = nil
        
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Use the provider type as the keychain ID (this is what the services expect)
        let keychainId = provider.type.rawValue
        
        // Store the existing key if any
        let existingKey = KeychainService.shared.getAPIKey(for: keychainId)
        
        // Temporarily save the new key for testing with the correct provider type ID
        let tempSaved = KeychainService.shared.saveAPIKey(trimmedKey, for: keychainId)
        
        guard tempSaved else {
            testResult = .failure("Errore nel salvare temporaneamente l'API key")
            isTestingConnection = false
            return
        }
        
        // Convert provider to AgentType for testing
        let agentType: AgentType
        switch provider.type {
        case .openai:
            agentType = .openAI
        case .anthropic:
            agentType = .claude
        case .mistral:
            agentType = .mistral
        case .perplexity:
            agentType = .perplexity
        case .n8n:
            agentType = .n8n
        case .custom:
            agentType = .custom
        case .grok:
             agentType = .grok
        case .deepSeek:
             agentType = .deepSeek
        }
        
        // Test the connection
        do {
            let isAvailable = await UniversalAssistantService.shared.isProviderAvailable(agentType)
            if isAvailable {
                testResult = .success
            } else {
                testResult = .failure("Test di connessione fallito - Provider non disponibile")
            }
        } catch {
            testResult = .failure("Test di connessione fallito: \(error.localizedDescription)")
        }
        
        // Restore the original key or remove the temporary one
        if let existingKey = existingKey {
            // Restore the original key
            KeychainService.shared.saveAPIKey(existingKey, for: keychainId)
        } else {
            // Remove the temporary key since there was no existing key
            KeychainService.shared.deleteAPIKey(for: keychainId)
        }
        
        isTestingConnection = false
    }
}

// MARK: - Preview
#Preview {
    APIKeyConfigView(provider: AssistantProvider.defaultProviders[0])
}
