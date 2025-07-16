//
//  N8NWorkflowManager.swift
//  AgentChat
//
//  Created by Mario Moschetta on 14/07/25.
//

import Foundation
import Combine

// MARK: - N8N Workflow Manager
class N8NWorkflowManager: ObservableObject {
    @Published var availableWorkflows: [N8NWorkflow] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let userDefaultsKey = "n8n_workflows"
    private let keychainService = KeychainService.shared
    
    // MARK: - Singleton
    static let shared = N8NWorkflowManager()
    
    private init() {
        loadWorkflows()
    }
    
    // MARK: - Public Methods
    
    /// Carica tutti i workflow (predefiniti + personalizzati)
    func loadWorkflows() {
        isLoading = true
        errorMessage = nil
        
        // Carica workflow predefiniti
        let defaultWorkflows = N8NWorkflow.defaultWorkflows
        
        // Carica workflow personalizzati
        let customWorkflows = self.loadCustomWorkflows()
        
        // Combina e ordina per categoria
        self.availableWorkflows = (defaultWorkflows + customWorkflows)
            .sorted { $0.category.rawValue < $1.category.rawValue }
        
        self.isLoading = false
    }
    
    /// Aggiunge un nuovo workflow personalizzato
    func addCustomWorkflow(_ workflow: N8NWorkflow) {
        var customWorkflow = workflow
        customWorkflow = N8NWorkflow(
            id: workflow.id,
            name: workflow.name,
            endpoint: workflow.endpoint,
            description: workflow.description,
            icon: workflow.icon,
            parameters: workflow.parameters,
            requiresAuthentication: workflow.requiresAuthentication,
            isActive: workflow.isActive,
            category: workflow.category,
            isDefault: false // Sempre false per workflow personalizzati
        )
        
        availableWorkflows.append(customWorkflow)
        saveCustomWorkflows()
        
        // Riordina per categoria
        availableWorkflows.sort { $0.category.rawValue < $1.category.rawValue }
    }
    
    /// Rimuove un workflow (solo personalizzati)
    func removeWorkflow(withId id: String) {
        guard let workflow = availableWorkflows.first(where: { $0.id == id }),
              !workflow.isDefault else {
            errorMessage = "Non è possibile rimuovere workflow predefiniti"
            return
        }
        
        availableWorkflows.removeAll { $0.id == id }
        saveCustomWorkflows()
    }
    
    /// Aggiorna un workflow esistente
    func updateWorkflow(_ updatedWorkflow: N8NWorkflow) {
        guard let index = availableWorkflows.firstIndex(where: { $0.id == updatedWorkflow.id }) else {
            errorMessage = "Workflow non trovato"
            return
        }
        
        // Non permettere modifica di workflow predefiniti
        if availableWorkflows[index].isDefault {
            errorMessage = "Non è possibile modificare workflow predefiniti"
            return
        }
        
        availableWorkflows[index] = updatedWorkflow
        saveCustomWorkflows()
    }
    
    /// Attiva/disattiva un workflow
    func toggleWorkflowStatus(withId id: String) {
        guard let index = availableWorkflows.firstIndex(where: { $0.id == id }) else {
            errorMessage = "Workflow non trovato"
            return
        }
        
        let workflow = availableWorkflows[index]
        let updatedWorkflow = N8NWorkflow(
            id: workflow.id,
            name: workflow.name,
            endpoint: workflow.endpoint,
            description: workflow.description,
            icon: workflow.icon,
            parameters: workflow.parameters,
            requiresAuthentication: workflow.requiresAuthentication,
            isActive: !workflow.isActive,
            category: workflow.category,
            isDefault: workflow.isDefault
        )
        
        availableWorkflows[index] = updatedWorkflow
        
        if !workflow.isDefault {
            saveCustomWorkflows()
        }
    }
    
    func toggleWorkflowStatus(_ workflow: N8NWorkflow) {
        var updatedWorkflow = workflow
        updatedWorkflow = N8NWorkflow(
            id: workflow.id,
            name: workflow.name,
            endpoint: workflow.endpoint,
            description: workflow.description,
            icon: workflow.icon,
            parameters: workflow.parameters,
            requiresAuthentication: workflow.requiresAuthentication,
            isActive: !workflow.isActive,
            category: workflow.category,
            isDefault: workflow.isDefault
        )
        
        if let index = availableWorkflows.firstIndex(where: { $0.id == workflow.id }) {
            availableWorkflows[index] = updatedWorkflow
            
            if !workflow.isDefault {
                saveCustomWorkflows()
            }
        }
    }
    
    /// Ottiene workflow attivi per categoria
    func getActiveWorkflows(for category: WorkflowCategory? = nil) -> [N8NWorkflow] {
        let activeWorkflows = availableWorkflows.filter { $0.isActive }
        
        if let category = category {
            return activeWorkflows.filter { $0.category == category }
        }
        
        return activeWorkflows
    }
    
    /// Ottiene un workflow specifico per ID
    func getWorkflow(withId id: String) -> N8NWorkflow? {
        return availableWorkflows.first { $0.id == id }
    }
    
    /// Valida un workflow prima del salvataggio
    func validateWorkflow(_ workflow: N8NWorkflow) -> ValidationResult {
        // Verifica nome non vuoto
        guard !workflow.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .failure("Il nome del workflow è obbligatorio")
        }
        
        // Verifica URL valido
        guard URL(string: workflow.endpoint) != nil else {
            return .failure("L'endpoint URL non è valido")
        }
        
        // Verifica che non esista già un workflow con lo stesso nome (escludendo se stesso)
        let existingWorkflow = availableWorkflows.first { $0.name.lowercased() == workflow.name.lowercased() && $0.id != workflow.id }
        if existingWorkflow != nil {
            return .failure("Esiste già un workflow con questo nome")
        }
        
        // Verifica parametri
        for parameter in workflow.parameters {
            if parameter.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return .failure("Tutti i parametri devono avere un nome")
            }
            
            // Verifica opzioni per parametri select
            if parameter.type == .select && (parameter.selectOptions?.isEmpty ?? true) {
                return .failure("I parametri di tipo 'Selezione' devono avere almeno un'opzione")
            }
        }
        
        return .success
    }
    
    /// Salva/rimuove API key per workflow che richiedono autenticazione
    func saveAPIKey(_ apiKey: String, for workflowId: String) {
        let key = "n8n_workflow_\(workflowId)"
        _ = keychainService.saveAPIKey(apiKey, for: key)
    }
    
    func getAPIKey(for workflowId: String) -> String? {
        let key = "n8n_workflow_\(workflowId)"
        return keychainService.getAPIKey(for: key)
    }
    
    func removeAPIKey(for workflowId: String) {
        let key = "n8n_workflow_\(workflowId)"
        _ = keychainService.deleteAPIKey(for: key)
    }
    
    // MARK: - Private Methods
    
    /// Carica workflow personalizzati da UserDefaults
    private func loadCustomWorkflows() -> [N8NWorkflow] {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let workflows = try? JSONDecoder().decode([N8NWorkflow].self, from: data) else {
            return []
        }
        return workflows
    }
    
    /// Salva workflow personalizzati in UserDefaults
    private func saveCustomWorkflows() {
        let customWorkflows = availableWorkflows.filter { !$0.isDefault }
        
        do {
            let data = try JSONEncoder().encode(customWorkflows)
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        } catch {
            errorMessage = "Errore nel salvataggio dei workflow: \(error.localizedDescription)"
        }
    }
    
    /// Ripristina workflow predefiniti
    func resetToDefaults() {
        // Rimuovi tutti i workflow personalizzati
        availableWorkflows = N8NWorkflow.defaultWorkflows
        
        // Pulisci UserDefaults
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
        
        // Rimuovi tutte le API key dei workflow personalizzati
        let customWorkflows = loadCustomWorkflows()
        for workflow in customWorkflows {
            removeAPIKey(for: workflow.id)
        }
    }
}

// MARK: - Validation Result
enum ValidationResult {
    case success
    case failure(String)
    
    var isValid: Bool {
        switch self {
        case .success: return true
        case .failure: return false
        }
    }
    
    var errorMessage: String? {
        switch self {
        case .success: return nil
        case .failure(let message): return message
        }
    }
}

// MARK: - Workflow Statistics
extension N8NWorkflowManager {
    var totalWorkflows: Int {
        availableWorkflows.count
    }
    
    var activeWorkflows: Int {
        availableWorkflows.filter { $0.isActive }.count
    }
    
    var customWorkflows: Int {
        availableWorkflows.filter { !$0.isDefault }.count
    }
    
    var workflowsByCategory: [WorkflowCategory: Int] {
        var categoryCount: [WorkflowCategory: Int] = [:]
        
        for workflow in availableWorkflows {
            categoryCount[workflow.category, default: 0] += 1
        }
        
        return categoryCount
    }
}