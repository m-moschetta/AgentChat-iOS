//
//  N8NService.swift
//  AgentChat
//
//  Created by Mario Moschetta on 04/07/25.
//

import Foundation

// MARK: - N8N Service
class N8NService: ChatServiceProtocol {
    static let shared = N8NService()
    
    private var sessionIds: [String: String] = [:] // chatId -> sessionId
    private let keychainService = KeychainService.shared
    
    private init() {}
    
    // MARK: - ChatServiceProtocol Implementation
    
    var supportedModels: [String] {
        return N8NWorkflowManager.shared.getActiveWorkflows().map { $0.id }
    }
    
    var providerName: String {
        return "n8n"
    }
    
    func sendMessage(_ message: String, model: String?) async throws -> String {
        guard let workflowId = model,
              let workflow = N8NWorkflowManager.shared.getWorkflow(withId: workflowId) else {
            throw ChatServiceError.unsupportedModel(model ?? "unknown")
        }
        
        guard workflow.isActive else {
            throw ChatServiceError.invalidConfiguration
        }
        
        return try await sendMessageToN8N(message: message, workflow: workflow)
    }
    
    func validateConfiguration() async throws -> Bool {
        let activeWorkflows = N8NWorkflowManager.shared.getActiveWorkflows()
        guard !activeWorkflows.isEmpty else {
            throw ChatServiceError.missingAPIKey("No active n8n workflows configured")
        }
        
        // Verifica che i workflow che richiedono autenticazione abbiano le API key
        for workflow in activeWorkflows {
            if workflow.requiresAuthentication {
                guard getAPIKey(for: workflow.id) != nil else {
                    throw ChatServiceError.missingAPIKey("API key missing for workflow: \(workflow.name)")
                }
            }
        }
        
        return true
    }
    
    private func sendMessageToN8N(message: String, workflow: N8NWorkflow) async throws -> String {
        // Prepara i parametri base
        var parameters: [String: Any] = [:]
        
        // Aggiungi il messaggio come parametro principale
        parameters["message"] = message
        parameters["input"] = message
        parameters["text"] = message
        
        // I parametri verranno aggiunti dall'utente tramite l'interfaccia
        
        do {
            let response = try await executeWorkflow(workflow, parameters: parameters, chatId: UUID().uuidString)
            return extractResponseMessage(from: response)
        } catch let error as N8NError {
            throw mapN8NErrorToChatServiceError(error)
        } catch {
            throw ChatServiceError.networkError(error)
        }
    }
    
    private func extractResponseMessage(from response: N8NResponse) -> String {
        // Prova a estrarre il messaggio dalla risposta in vari modi
        if let message = response.message, !message.isEmpty {
            return message
        }
        
        // Prova a estrarre dai dati
        if let data = response.data {
            // Se data è una stringa
            if let stringData = data as? String {
                return stringData
            }
            
            // Se data è un dizionario, cerca campi comuni
            if let dictData = data as? [String: Any] {
                let commonKeys = ["result", "output", "response", "message", "text", "content"]
                for key in commonKeys {
                    if let value = dictData[key] as? String, !value.isEmpty {
                        return value
                    }
                }
                
                // Se non trova nulla, restituisce una rappresentazione JSON
                if let jsonData = try? JSONSerialization.data(withJSONObject: dictData, options: .prettyPrinted),
                   let jsonString = String(data: jsonData, encoding: .utf8) {
                    return jsonString
                }
            }
        }
        
        return "Workflow executed successfully"
    }
    
    private func mapN8NErrorToChatServiceError(_ error: N8NError) -> ChatServiceError {
        switch error {
        case .authenticationRequired:
            return .authenticationFailed
        case .workflowNotFound:
            return .invalidConfiguration
        case .invalidURL:
            return .invalidConfiguration
        case .invalidResponse:
            return .invalidResponse
        case .networkError(let underlyingError):
            return .networkError(underlyingError)
        case .serverError(let message):
            return .serverError(message)
        case .missingRequiredParameter(let param):
            return .invalidConfiguration
        }
    }
    
    // MARK: - Public Methods
    
    /// Esegue un workflow n8n con i parametri specificati
    func executeWorkflow(_ workflow: N8NWorkflow, parameters: [String: Any], chatId: String) async throws -> N8NResponse {
        // Valida parametri obbligatori
        try validateRequiredParameters(workflow: workflow, parameters: parameters)
        
        // Crea richiesta
        let sessionId = sessionIds[chatId]
        let request = N8NRequest(chatId: chatId, parameters: parameters, sessionId: sessionId)
        
        // Effettua chiamata
        let response = try await callEndpoint(workflow: workflow, request: request)
        
        // Aggiorna session ID se presente
        if let newSessionId = response.sessionId {
            sessionIds[chatId] = newSessionId
        }
        
        return response
    }
    
    /// Effettua chiamata HTTP POST all'endpoint del workflow
    func callEndpoint(workflow: N8NWorkflow, request: N8NRequest) async throws -> N8NResponse {
        guard let url = URL(string: workflow.endpoint) else {
            throw N8NError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Aggiungi autenticazione se richiesta
        if workflow.requiresAuthentication {
            guard let apiKey = getAPIKey(for: workflow.id) else {
                throw N8NError.authenticationRequired
            }
            urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
        
        // Codifica richiesta
        do {
            let requestData = try JSONEncoder().encode(request)
            urlRequest.httpBody = requestData
        } catch {
            throw N8NError.networkError(error)
        }
        
        // Effettua chiamata
        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw N8NError.invalidResponse
            }
            
            // Gestisci codici di errore HTTP
            switch httpResponse.statusCode {
            case 200...299:
                break
            case 401:
                throw N8NError.authenticationRequired
            case 404:
                throw N8NError.workflowNotFound
            default:
                let errorMessage = String(data: data, encoding: .utf8) ?? "Errore sconosciuto"
                throw N8NError.serverError(errorMessage)
            }
            
            // Decodifica risposta
            let n8nResponse = try JSONDecoder().decode(N8NResponse.self, from: data)
            return n8nResponse
            
        } catch let error as N8NError {
            throw error
        } catch {
            throw N8NError.networkError(error)
        }
    }
    
    /// Invia messaggio legacy per compatibilità con il vecchio sistema
    func sendMessage(_ message: String, chatId: String) async throws -> String {
        // Cerca workflow "Blog Creator" predefinito
        let workflowManager = N8NWorkflowManager.shared
        guard let blogWorkflow = workflowManager.availableWorkflows.first(where: { $0.name == "Blog Creator" && $0.isActive }) else {
            throw N8NError.workflowNotFound
        }
        
        let action = determineAction(from: message)
        let parameters = createLegacyParameters(for: action, message: message)
        
        let response = try await executeWorkflow(blogWorkflow, parameters: parameters, chatId: chatId)
        return formatLegacyResponse(response, for: action)
    }
    
    /// Valida connessione a un workflow
    func validateConnection(for workflow: N8NWorkflow) async throws -> Bool {
        let testParameters: [String: Any] = ["test": true]
        let testRequest = N8NRequest(chatId: "test", parameters: testParameters)
        
        do {
            let _ = try await callEndpoint(workflow: workflow, request: testRequest)
            return true
        } catch {
            throw error
        }
    }
    
    /// Pulisce sessione per una chat
    func clearSession(for chatId: String) {
        sessionIds.removeValue(forKey: chatId)
    }
    
    /// Pulisce tutte le sessioni
    func clearAllSessions() {
        sessionIds.removeAll()
    }
    
    // MARK: - API Key Management
    
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
    
    private func validateRequiredParameters(workflow: N8NWorkflow, parameters: [String: Any]) throws {
        for parameter in workflow.parameters where parameter.isRequired {
            guard let value = parameters[parameter.name],
                  !String(describing: value).trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw N8NError.missingRequiredParameter(parameter.name)
            }
        }
    }
    
    // MARK: - Legacy Support Methods
    
    private func determineAction(from message: String) -> N8NAction {
        let lowercased = message.lowercased()
        
        if lowercased.contains("genera") || lowercased.contains("crea") {
            return .generate
        } else if lowercased.contains("approva") || lowercased.contains("pubblica") {
            return .approve
        } else if lowercased.contains("modifica") || lowercased.contains("cambia") {
            return .modify
        } else {
            return .generate
        }
    }
    
    private func createLegacyParameters(for action: N8NAction, message: String) -> [String: Any] {
        return [
            "action": action.rawValue,
            "message": message,
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]
    }
    
    private func formatLegacyResponse(_ response: N8NResponse, for action: N8NAction) -> String {
        guard response.success else {
            let errorMessage = response.message ?? "Errore sconosciuto"
            return "❌ Errore: \(errorMessage)"
        }
        
        switch action {
        case .generate:
            if let previewContent = response.previewContent {
                return "📝 **Contenuto generato:**\n\n\(previewContent)\n\n💡 Vuoi approvare e pubblicare questo contenuto? Scrivi 'approva' per procedere."
            }
        case .approve:
            if let data = response.data, let publishUrl = data["publish_url"] as? String {
                return "✅ **Contenuto pubblicato con successo!**\n\n🔗 URL: \(publishUrl)"
            } else {
                return "✅ **Contenuto approvato e pubblicato con successo!**"
            }
        case .modify:
            if let previewContent = response.previewContent {
                return "✏️ **Contenuto modificato:**\n\n\(previewContent)\n\n💡 Vuoi approvare questa versione? Scrivi 'approva' per procedere."
            }
        }
        
        return response.message ?? "Operazione completata"
    }
}

// MARK: - N8N Action
enum N8NAction: String {
    case generate = "generate"
    case approve = "approve"
    case modify = "modify"
}

// MARK: - Parameter Value Conversion
extension N8NService {
    /// Converte valori dei parametri nel tipo corretto
    func convertParameterValue(_ value: String, for parameter: N8NParameter) -> Any {
        switch parameter.type {
        case .text, .multiline, .select:
            return value
        case .number:
            return Double(value) ?? 0
        case .boolean:
            return value.lowercased() == "true" || value == "1" || value.lowercased() == "sì"
        }
    }
    
    /// Valida valore di un parametro
    func validateParameterValue(_ value: String, for parameter: N8NParameter) -> Bool {
        switch parameter.type {
        case .text, .multiline:
            return !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .number:
            return Double(value) != nil
        case .boolean:
            let lowercased = value.lowercased()
            return ["true", "false", "1", "0", "sì", "no"].contains(lowercased)
        case .select:
            return parameter.selectOptions?.contains(value) ?? false
        }
    }
}

// MARK: - N8N Errors
// N8NError è definito in N8NWorkflow.swift