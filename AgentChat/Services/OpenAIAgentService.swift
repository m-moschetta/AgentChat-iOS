//
//  OpenAIAgentService.swift
//  AgentChat
//
//  Created by Mario Moschetta on 04/07/25.
//

import Foundation

// MARK: - OpenAI Request/Response Transformers
class OpenAIRequestTransformer: RequestTransformer {
    func transform(_ request: UnifiedChatRequest) throws -> Data {
        let openAIRequest = OpenAIRequest(
            model: request.model,
            messages: request.messages.map { OpenAIMessage(role: $0.role, content: $0.content) },
            maxTokens: request.parameters.maxTokens,
            temperature: request.parameters.temperature,
            stream: request.parameters.stream ?? false
        )
        
        return try JSONEncoder().encode(openAIRequest)
    }
}

class OpenAIResponseParser: ResponseParser {
    func parse(_ data: Data) throws -> UnifiedChatResponse {
        // Prima prova a decodificare come errore
        if let errorResponse = try? JSONDecoder().decode(OpenAIErrorResponse.self, from: data) {
            throw parseOpenAIError(errorResponse)
        }
        
        // Se non è un errore, prova a decodificare come risposta normale
        do {
            let openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
            
            guard let choice = openAIResponse.choices.first else {
                throw ChatServiceError.invalidResponse
            }
            
            let message = choice.message
            
            return UnifiedChatResponse(
                content: message.content,
                model: openAIResponse.model,
                usage: openAIResponse.usage.map { (usage: OpenAIUsage) in
                    TokenUsage(
                        promptTokens: usage.promptTokens,
                        completionTokens: usage.completionTokens,
                        totalTokens: usage.totalTokens
                    )
                }
            )
        } catch {
            // Se il parsing fallisce, prova a estrarre informazioni di errore dal JSON grezzo
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = json["error"] as? [String: Any],
               let message = error["message"] as? String {
                
                // Gestisci errori specifici per modelli o3
                if message.contains("model") && (message.contains("o3") || message.contains("does not exist")) {
                    throw ChatServiceError.unsupportedModel("Il modello o3 non è disponibile per il tuo account. Verifica il tuo livello di accesso API OpenAI.")
                }
                
                if let code = error["code"] as? String {
                    switch code {
                    case "model_not_found":
                        throw ChatServiceError.unsupportedModel(message)
                    case "insufficient_quota":
                        throw ChatServiceError.rateLimitExceeded
                    case "invalid_api_key":
                        throw ChatServiceError.authenticationFailed
                    default:
                        throw ChatServiceError.serverError(message)
                    }
                } else {
                    throw ChatServiceError.serverError(message)
                }
            }
            
            throw ChatServiceError.invalidResponse
        }
    }
    
    private func parseOpenAIError(_ errorResponse: OpenAIErrorResponse) -> ChatServiceError {
        let error = errorResponse.error
        
        // Gestisci errori specifici per modelli o3
        if error.message.contains("model") && (error.message.contains("o3") || error.message.contains("does not exist")) {
            return ChatServiceError.unsupportedModel("Il modello o3 non è disponibile per il tuo account. Verifica il tuo livello di accesso API OpenAI (richiede livello 4 o 5).")
        }
        
        switch error.code {
        case "model_not_found":
            return ChatServiceError.unsupportedModel(error.message)
        case "insufficient_quota":
            return ChatServiceError.rateLimitExceeded
        case "invalid_api_key":
            return ChatServiceError.authenticationFailed
        case "rate_limit_exceeded":
            return ChatServiceError.rateLimitExceeded
        case "context_length_exceeded":
            return ChatServiceError.serverError("Messaggio troppo lungo per il modello selezionato")
        default:
            return ChatServiceError.serverError(error.message)
        }
    }
}

// MARK: - OpenAI Data Models
// OpenAI models are defined in ProviderModels.swift

// MARK: - OpenAI Agent Service
class OpenAIAgentService: BaseAgentService {
    
    // MARK: - Properties
    private let httpService: BaseHTTPService
    
    // MARK: - Initialization
    init(configuration: AgentConfiguration? = nil, session: URLSession = .shared, memoryManager: AgentMemoryManager? = nil) {
        self.httpService = BaseHTTPService(
            configuration: .openAI,
            requestTransformer: OpenAIRequestTransformer(),
            responseParser: OpenAIResponseParser(),
            session: session
        )
        
        super.init(configuration: configuration, memoryManager: memoryManager)
    }
    
    // MARK: - AgentServiceProtocol Implementation
    override var supportedModels: [String] {
        return [
            "gpt-4.1",
            "gpt-4.1-mini",
            "gpt-4.1-nano",
            "gpt-4o",
            "gpt-4o-mini",
            "o3",
            "o3-pro",
            "o4-mini",
            "o4-mini-high",
            "gpt-3.5-turbo"
        ]
    }
    
    override var providerName: String {
        return agentConfiguration?.name ?? "OpenAI Agent"
    }
    
    override var capabilities: [AgentCapability] {
        return [
            .textGeneration,
            .codeGeneration,
            .dataAnalysis,
            .memoryRetention,
            .collaboration,
            .multiModalInput
        ]
    }
    
    override func sendMessage(_ message: String, model: String?) async throws -> String {
        let selectedModel = model ?? agentConfiguration?.model ?? "gpt-4o-mini"
        
        let unifiedRequest = UnifiedChatRequest(
            model: selectedModel,
            messages: [ChatMessage(role: "user", content: message)],
            parameters: RequestParameters(
                temperature: agentConfiguration?.temperature,
                maxTokens: agentConfiguration?.maxTokens
            )
        )
        
        let response = try await httpService.sendUnifiedRequest(unifiedRequest)
        
        // Save conversation context using memory manager
        if let agentId = agentConfiguration?.id {
            var context = ConversationContext(chatId: UUID(), agentId: agentId)
            context.messages.append(ContextMessage(role: "assistant", content: response.content, metadata: ["model": response.model ?? "unknown"]))
            do {
                try await saveConversationContext(context)
            } catch {
                print("Failed to save conversation context: \(error.localizedDescription)")
            }
        }
        
        return response.content
    }
    

    
    override func processCollaborativeMessage(_ message: CollaborativeMessage) async throws -> String {
        guard isMultiAgentCapable else {
            throw AgentServiceError.collaborationNotSupported
        }
        
        // Costruisci un prompt specifico per la collaborazione
        var collaborativePrompt = ""
        
        if let taskContext = message.taskContext {
            collaborativePrompt += "Task Type: \(taskContext.taskType.rawValue)\n"
            collaborativePrompt += "Task ID: \(taskContext.taskId)\n"
            if let deadline = taskContext.deadline {
                collaborativePrompt += "Deadline: \(deadline)\n"
            }
            collaborativePrompt += "\n"
        }
        
        collaborativePrompt += "Collaborative Message from Agent \(message.fromAgent):\n"
        collaborativePrompt += message.content
        collaborativePrompt += "\n\nPlease provide a response that contributes to this collaborative task."
        
        return try await sendMessage(collaborativePrompt, model: nil)
    }
    
    // MARK: - OpenAI Specific Methods
    func sendMessageWithCustomParameters(
        _ message: String,
        model: String? = nil,
        temperature: Double? = nil,
        maxTokens: Int? = nil,
        topP: Double? = nil
    ) async throws -> String {
        // Utilizza i parametri personalizzati se forniti, altrimenti usa quelli della configurazione
        let config = agentConfiguration
        let finalTemperature = temperature ?? config?.temperature ?? 0.7
        let finalMaxTokens = maxTokens ?? config?.maxTokens ?? 4000
        let finalTopP = topP ?? 1.0
        
        // Crea una richiesta unificata con parametri personalizzati
        let unifiedRequest = UnifiedChatRequest(
            model: model ?? supportedModels.first ?? "gpt-4.1-mini",
            messages: [ChatMessage(role: "user", content: message)],
            parameters: RequestParameters(
                temperature: finalTemperature,
                maxTokens: finalMaxTokens,
                topP: finalTopP,
                stream: false
            )
        )
        
        // Invia tramite HTTP service (metodo privato da esporre)
        return try await sendUnifiedRequest(unifiedRequest)
    }
    
    private func sendUnifiedRequest(_ request: UnifiedChatRequest) async throws -> String {
        // Utilizza il metodo esposto da BaseHTTPService
        let response = try await httpService.sendUnifiedRequest(request)
        return response.content
    }
    
    // MARK: - Model Management
    func getAvailableModels() async throws -> [String] {
        return supportedModels
    }
    
    func getModelInfo(for model: String) -> OpenAIModelInfo? {
        return OpenAIModelInfo.getInfo(for: model)
    }
}

// MARK: - OpenAI Model Information
struct OpenAIModelInfo {
    let name: String
    let description: String
    let contextWindow: Int
    let maxTokens: Int
    let costPer1KTokens: Double
    let capabilities: [String]
    
    static func getInfo(for model: String) -> OpenAIModelInfo? {
        switch model {
        case "o3":
            return OpenAIModelInfo(
                name: "o3",
                description: "Most advanced reasoning model",
                contextWindow: 128000,
                maxTokens: 65536,
                costPer1KTokens: 0.06,
                capabilities: ["reasoning", "coding", "math", "science"]
            )
        case "o1":
            return OpenAIModelInfo(
                name: "o1",
                description: "Advanced reasoning model",
                contextWindow: 128000,
                maxTokens: 32768,
                costPer1KTokens: 0.015,
                capabilities: ["reasoning", "coding", "math"]
            )
        case "gpt-4o":
            return OpenAIModelInfo(
                name: "gpt-4o",
                description: "High-intelligence flagship model",
                contextWindow: 128000,
                maxTokens: 16384,
                costPer1KTokens: 0.005,
                capabilities: ["text", "vision", "audio", "coding"]
            )
        case "gpt-4o-mini":
            return OpenAIModelInfo(
                name: "gpt-4o-mini",
                description: "Affordable and intelligent small model",
                contextWindow: 128000,
                maxTokens: 16384,
                costPer1KTokens: 0.00015,
                capabilities: ["text", "vision", "coding"]
            )
        default:
            return nil
        }
    }
    
    static let allModels: [OpenAIModelInfo] = [
        getInfo(for: "o3")!,
        getInfo(for: "o1")!,
        getInfo(for: "gpt-4o")!,
        getInfo(for: "gpt-4o-mini")!
    ]
}

// MARK: - Factory Extension
extension ServiceFactory {
    func createOpenAIAgentService(with configuration: AgentConfiguration, memoryManager: AgentMemoryManager? = nil) -> OpenAIAgentService {
        return OpenAIAgentService(configuration: configuration, memoryManager: memoryManager)
    }
}