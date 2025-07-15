//
//  N8NWorkflow.swift
//  AgentChat
//
//  Created by Mario Moschetta on 14/07/25.
//

import Foundation

// MARK: - Parameter Type
enum ParameterType: String, Codable, CaseIterable {
    case text = "text"
    case number = "number"
    case boolean = "boolean"
    case select = "select"
    case multiline = "multiline"
    
    var displayName: String {
        switch self {
        case .text: return "Testo"
        case .number: return "Numero"
        case .boolean: return "Booleano"
        case .select: return "Selezione"
        case .multiline: return "Testo Multiriga"
        }
    }
}

// MARK: - Workflow Category
enum WorkflowCategory: String, Codable, CaseIterable {
    case blogCreation = "blog_creation"
    case contentGeneration = "content_generation"
    case socialMedia = "social_media"
    case automation = "automation"
    case custom = "custom"
    
    var displayName: String {
        switch self {
        case .blogCreation: return "Creazione Blog"
        case .contentGeneration: return "Generazione Contenuti"
        case .socialMedia: return "Social Media"
        case .automation: return "Automazione"
        case .custom: return "Personalizzato"
        }
    }
    
    var icon: String {
        switch self {
        case .blogCreation: return "doc.text"
        case .contentGeneration: return "text.bubble"
        case .socialMedia: return "person.2"
        case .automation: return "gearshape.2"
        case .custom: return "wrench.and.screwdriver"
        }
    }
}

// MARK: - N8N Parameter
struct N8NParameter: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let type: ParameterType
    let isRequired: Bool
    let placeholder: String
    let description: String
    let selectOptions: [String]? // Solo per tipo select
    
    init(id: String = UUID().uuidString, name: String, type: ParameterType, isRequired: Bool = false, placeholder: String = "", description: String = "", selectOptions: [String]? = nil) {
        self.id = id
        self.name = name
        self.type = type
        self.isRequired = isRequired
        self.placeholder = placeholder
        self.description = description
        self.selectOptions = selectOptions
    }
    
    static func == (lhs: N8NParameter, rhs: N8NParameter) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - N8N Workflow
struct N8NWorkflow: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let endpoint: String
    let description: String
    let icon: String
    let parameters: [N8NParameter]
    let requiresAuthentication: Bool
    let isActive: Bool
    let category: WorkflowCategory
    let isDefault: Bool // Per distinguere workflow predefiniti da personalizzati
    
    init(id: String = UUID().uuidString, name: String, endpoint: String, description: String, icon: String? = nil, parameters: [N8NParameter] = [], requiresAuthentication: Bool = false, isActive: Bool = true, category: WorkflowCategory = .custom, isDefault: Bool = false) {
        self.id = id
        self.name = name
        self.endpoint = endpoint
        self.description = description
        self.icon = icon ?? category.icon
        self.parameters = parameters
        self.requiresAuthentication = requiresAuthentication
        self.isActive = isActive
        self.category = category
        self.isDefault = isDefault
    }
    
    static func == (lhs: N8NWorkflow, rhs: N8NWorkflow) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - N8N Request/Response Models
struct N8NRequest: Codable {
    let chatId: String
    let parameters: [String: Any]
    let sessionId: String?
    
    enum CodingKeys: String, CodingKey {
        case chatId = "chat_id"
        case parameters
        case sessionId = "session_id"
    }
    
    init(chatId: String, parameters: [String: Any], sessionId: String? = nil) {
        self.chatId = chatId
        self.parameters = parameters
        self.sessionId = sessionId
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        chatId = try container.decode(String.self, forKey: .chatId)
        sessionId = try container.decodeIfPresent(String.self, forKey: .sessionId)
        
        // Decode parameters from JSON string
        let parametersString = try container.decode(String.self, forKey: .parameters)
        if let parametersData = parametersString.data(using: .utf8),
           let parametersDict = try JSONSerialization.jsonObject(with: parametersData) as? [String: Any] {
            parameters = parametersDict
        } else {
            parameters = [:]
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(chatId, forKey: .chatId)
        try container.encodeIfPresent(sessionId, forKey: .sessionId)
        
        // Encode parameters as JSON
        let parametersData = try JSONSerialization.data(withJSONObject: parameters)
        let parametersString = String(data: parametersData, encoding: .utf8) ?? "{}"
        try container.encode(parametersString, forKey: .parameters)
    }
}

struct N8NResponse: Codable {
    let success: Bool
    let message: String?
    let data: [String: Any]?
    let sessionId: String?
    let requiresApproval: Bool?
    let previewContent: String?
    
    enum CodingKeys: String, CodingKey {
        case success
        case message
        case data
        case sessionId = "session_id"
        case requiresApproval = "requires_approval"
        case previewContent = "preview_content"
    }
    
    init(success: Bool, message: String? = nil, data: [String: Any]? = nil, sessionId: String? = nil, requiresApproval: Bool? = nil, previewContent: String? = nil) {
        self.success = success
        self.message = message
        self.data = data
        self.sessionId = sessionId
        self.requiresApproval = requiresApproval
        self.previewContent = previewContent
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        success = try container.decode(Bool.self, forKey: .success)
        message = try container.decodeIfPresent(String.self, forKey: .message)
        sessionId = try container.decodeIfPresent(String.self, forKey: .sessionId)
        requiresApproval = try container.decodeIfPresent(Bool.self, forKey: .requiresApproval)
        previewContent = try container.decodeIfPresent(String.self, forKey: .previewContent)
        
        // Decode data from JSON object
        if let dataContainer = try? container.nestedContainer(keyedBy: AnyCodingKey.self, forKey: .data) {
            var dataDict: [String: Any] = [:]
            for key in dataContainer.allKeys {
                if let value = try? dataContainer.decode(String.self, forKey: key) {
                    dataDict[key.stringValue] = value
                } else if let value = try? dataContainer.decode(Int.self, forKey: key) {
                    dataDict[key.stringValue] = value
                } else if let value = try? dataContainer.decode(Double.self, forKey: key) {
                    dataDict[key.stringValue] = value
                } else if let value = try? dataContainer.decode(Bool.self, forKey: key) {
                    dataDict[key.stringValue] = value
                }
            }
            data = dataDict.isEmpty ? nil : dataDict
        } else {
            data = nil
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(success, forKey: .success)
        try container.encodeIfPresent(message, forKey: .message)
        try container.encodeIfPresent(sessionId, forKey: .sessionId)
        try container.encodeIfPresent(requiresApproval, forKey: .requiresApproval)
        try container.encodeIfPresent(previewContent, forKey: .previewContent)
        
        // Encode data as JSON object
        if let data = data {
            var dataContainer = container.nestedContainer(keyedBy: AnyCodingKey.self, forKey: .data)
            for (key, value) in data {
                let codingKey = AnyCodingKey(stringValue: key)!
                if let stringValue = value as? String {
                    try dataContainer.encode(stringValue, forKey: codingKey)
                } else if let intValue = value as? Int {
                    try dataContainer.encode(intValue, forKey: codingKey)
                } else if let doubleValue = value as? Double {
                    try dataContainer.encode(doubleValue, forKey: codingKey)
                } else if let boolValue = value as? Bool {
                    try dataContainer.encode(boolValue, forKey: codingKey)
                }
            }
        }
    }
}

// MARK: - AnyCodingKey
struct AnyCodingKey: CodingKey {
    var stringValue: String
    var intValue: Int?
    
    init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }
    
    init?(intValue: Int) {
        self.stringValue = String(intValue)
        self.intValue = intValue
    }
}

// MARK: - N8N Error
enum N8NError: Error, LocalizedError {
    case invalidURL
    case missingRequiredParameter(String)
    case authenticationRequired
    case networkError(Error)
    case invalidResponse
    case workflowNotFound
    case serverError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL endpoint non valido"
        case .missingRequiredParameter(let param):
            return "Parametro obbligatorio mancante: \(param)"
        case .authenticationRequired:
            return "Autenticazione richiesta per questo workflow"
        case .networkError(let error):
            return "Errore di rete: \(error.localizedDescription)"
        case .invalidResponse:
            return "Risposta non valida dal server"
        case .workflowNotFound:
            return "Workflow non trovato"
        case .serverError(let message):
            return "Errore del server: \(message)"
        }
    }
}

// MARK: - Default Workflows
extension N8NWorkflow {
    static let defaultWorkflows: [N8NWorkflow] = [
        N8NWorkflow(
            name: "Blog Creator",
            endpoint: "https://your-n8n-instance.com/webhook/blog-creation",
            description: "Crea e pubblica automaticamente articoli di blog con contenuto ottimizzato SEO",
            icon: "doc.text",
            parameters: [
                N8NParameter(name: "topic", type: .text, isRequired: true, placeholder: "Argomento del blog", description: "L'argomento principale dell'articolo"),
                N8NParameter(name: "target_audience", type: .select, isRequired: true, placeholder: "Seleziona audience", description: "Il pubblico target dell'articolo", selectOptions: ["Principianti", "Intermedio", "Avanzato", "Generale"]),
                N8NParameter(name: "word_count", type: .number, isRequired: false, placeholder: "1000", description: "Numero di parole desiderato"),
                N8NParameter(name: "seo_keywords", type: .text, isRequired: false, placeholder: "keyword1, keyword2", description: "Parole chiave SEO separate da virgola")
            ],
            requiresAuthentication: false,
            category: .blogCreation,
            isDefault: true
        ),
        N8NWorkflow(
            name: "Social Media Generator",
            endpoint: "https://your-n8n-instance.com/webhook/social-media",
            description: "Genera contenuti ottimizzati per diverse piattaforme social media",
            icon: "person.2",
            parameters: [
                N8NParameter(name: "content_topic", type: .text, isRequired: true, placeholder: "Argomento del post", description: "L'argomento del contenuto social"),
                N8NParameter(name: "platform", type: .select, isRequired: true, placeholder: "Seleziona piattaforma", description: "Piattaforma social target", selectOptions: ["Instagram", "Facebook", "Twitter", "LinkedIn", "TikTok"]),
                N8NParameter(name: "tone", type: .select, isRequired: false, placeholder: "Seleziona tono", description: "Tono del contenuto", selectOptions: ["Professionale", "Casual", "Divertente", "Informativo", "Ispirante"]),
                N8NParameter(name: "include_hashtags", type: .boolean, isRequired: false, placeholder: "", description: "Includi hashtags nel contenuto")
            ],
            requiresAuthentication: false,
            category: .socialMedia,
            isDefault: true
        ),
        N8NWorkflow(
            name: "Content Optimizer",
            endpoint: "https://your-n8n-instance.com/webhook/content-optimizer",
            description: "Ottimizza contenuti esistenti per SEO e leggibilità",
            icon: "text.bubble",
            parameters: [
                N8NParameter(name: "original_content", type: .multiline, isRequired: true, placeholder: "Inserisci il contenuto da ottimizzare", description: "Il contenuto originale da migliorare"),
                N8NParameter(name: "optimization_type", type: .select, isRequired: true, placeholder: "Tipo di ottimizzazione", description: "Tipo di ottimizzazione richiesta", selectOptions: ["SEO", "Leggibilità", "Engagement", "Conversione"]),
                N8NParameter(name: "target_keywords", type: .text, isRequired: false, placeholder: "keyword1, keyword2", description: "Parole chiave target per SEO")
            ],
            requiresAuthentication: false,
            category: .contentGeneration,
            isDefault: true
        )
    ]
}