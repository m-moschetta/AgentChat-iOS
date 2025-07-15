//
//  LocalAssistantConfiguration.swift
//  AgentChat
//
//  Created by Mario Moschetta on 04/07/25.
//

import Foundation
import Combine

// MARK: - Local Assistant Configuration
class LocalAssistantConfiguration: ObservableObject {
    @Published var availableProviders: [AssistantProvider] = []
    @Published var customProviders: [AssistantProvider] = []
    
    private let userDefaults = UserDefaults.standard
    private let customProvidersKey = "customProviders"
    private let disabledProvidersKey = "disabledProviders"
    
    init() {
        setupDefaultProviders()
        loadCustomProviders()
        loadProviderStates()
    }
    
    // MARK: - Setup Default Providers
    private func setupDefaultProviders() {
        availableProviders = AssistantProvider.defaultProviders
    }
    
    // MARK: - Custom Providers Management
    func addCustomProvider(_ provider: AssistantProvider) {
        customProviders.append(provider)
        availableProviders.append(provider)
        saveCustomProviders()
    }
    
    func removeCustomProvider(withId id: String) {
        customProviders.removeAll { $0.id == id }
        availableProviders.removeAll { $0.id == id }
        saveCustomProviders()
    }
    
    func updateCustomProvider(_ provider: AssistantProvider) {
        if let index = customProviders.firstIndex(where: { $0.id == provider.id }) {
            customProviders[index] = provider
        }
        if let index = availableProviders.firstIndex(where: { $0.id == provider.id }) {
            availableProviders[index] = provider
        }
        saveCustomProviders()
    }
    
    // MARK: - Provider State Management
    func toggleProvider(_ provider: AssistantProvider) {
        let updatedProvider = AssistantProvider(
            id: provider.id,
            name: provider.name,
            type: provider.type,
            endpoint: provider.endpoint,
            apiKeyRequired: provider.apiKeyRequired,
            supportedModels: provider.supportedModels,
            defaultModel: provider.defaultModel,
            icon: provider.icon,
            description: provider.description,
            isActive: !provider.isActive
        )
        
        if let index = availableProviders.firstIndex(where: { $0.id == provider.id }) {
            availableProviders[index] = updatedProvider
        }
        
        if customProviders.contains(where: { $0.id == provider.id }) {
            updateCustomProvider(updatedProvider)
        } else {
            saveProviderStates()
        }
    }
    
    // MARK: - Active Providers
    var activeProviders: [AssistantProvider] {
        return availableProviders.filter { $0.isActive }
    }
    
    // MARK: - Provider Lookup
    func provider(withId id: String) -> AssistantProvider? {
        return availableProviders.first { $0.id == id }
    }
    
    func providers(ofType type: ProviderType) -> [AssistantProvider] {
        return availableProviders.filter { $0.type == type && $0.isActive }
    }
    
    // MARK: - API Key Management
    func hasValidAPIKey(for provider: AssistantProvider) -> Bool {
        guard provider.apiKeyRequired else { return true }
        // Use provider type as keychain ID to match what services expect
        return KeychainService.shared.hasAPIKey(for: provider.type.rawValue)
    }
    
    func setAPIKey(_ key: String, for provider: AssistantProvider) -> Bool {
        // Use provider type as keychain ID to match what services expect
        return KeychainService.shared.saveAPIKey(key, for: provider.type.rawValue)
    }
    
    func getAPIKey(for provider: AssistantProvider) -> String? {
        // Use provider type as keychain ID to match what services expect
        return KeychainService.shared.getAPIKey(for: provider.type.rawValue)
    }
    
    func removeAPIKey(for provider: AssistantProvider) -> Bool {
        // Use provider type as keychain ID to match what services expect
        return KeychainService.shared.deleteAPIKey(for: provider.type.rawValue)
    }
    
    // MARK: - Validation
    func validateProvider(_ provider: AssistantProvider) -> [String] {
        var errors: [String] = []
        
        if provider.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("Il nome del provider è obbligatorio")
        }
        
        if provider.endpoint.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("L'endpoint è obbligatorio")
        } else if !isValidURL(provider.endpoint) {
            errors.append("L'endpoint deve essere un URL valido")
        }
        
        if provider.supportedModels.isEmpty {
            errors.append("Almeno un modello deve essere specificato")
        }
        
        return errors
    }
    
    private func isValidURL(_ string: String) -> Bool {
        guard let url = URL(string: string) else { return false }
        return url.scheme != nil && url.host != nil
    }
    
    // MARK: - Persistence
    private func saveCustomProviders() {
        do {
            let data = try JSONEncoder().encode(customProviders)
            userDefaults.set(data, forKey: customProvidersKey)
        } catch {
            print("Errore nel salvare i provider personalizzati: \(error)")
        }
    }
    
    private func loadCustomProviders() {
        guard let data = userDefaults.data(forKey: customProvidersKey) else { return }
        
        do {
            customProviders = try JSONDecoder().decode([AssistantProvider].self, from: data)
            availableProviders.append(contentsOf: customProviders)
        } catch {
            print("Errore nel caricare i provider personalizzati: \(error)")
        }
    }
    
    private func saveProviderStates() {
        let disabledProviders = availableProviders.filter { !$0.isActive }.map { $0.id }
        userDefaults.set(disabledProviders, forKey: disabledProvidersKey)
    }
    
    private func loadProviderStates() {
        let disabledProviders = userDefaults.stringArray(forKey: disabledProvidersKey) ?? []
        
        for i in 0..<availableProviders.count {
            if disabledProviders.contains(availableProviders[i].id) {
                let provider = availableProviders[i]
                availableProviders[i] = AssistantProvider(
                    id: provider.id,
                    name: provider.name,
                    type: provider.type,
                    endpoint: provider.endpoint,
                    apiKeyRequired: provider.apiKeyRequired,
                    supportedModels: provider.supportedModels,
                    defaultModel: provider.defaultModel,
                    icon: provider.icon,
                    description: provider.description,
                    isActive: false
                )
            }
        }
    }
    
    // MARK: - Reset
    func resetToDefaults() {
        userDefaults.removeObject(forKey: customProvidersKey)
        userDefaults.removeObject(forKey: disabledProvidersKey)
        KeychainService.shared.clearAllAPIKeys()
        
        customProviders.removeAll()
        setupDefaultProviders()
    }
}