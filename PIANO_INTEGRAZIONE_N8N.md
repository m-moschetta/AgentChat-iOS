# Piano di Integrazione AgentChat con n8n

## Panoramica dell'Integrazione

n8n è una piattaforma di automazione workflow che può essere utilizzata per creare agenti AI personalizzati. L'integrazione permetterà ad AgentChat di comunicare con workflow n8n tramite API REST e WebHooks.

## Architettura dell'Integrazione

### 1. Componenti Principali

```
AgentChat (iOS) ←→ n8n API ←→ n8n Workflows ←→ AI Services
                                    ↓
                              Database/Storage
```

### 2. Flusso di Comunicazione

1. **User Input** → AgentChat iOS App
2. **HTTP Request** → n8n Webhook/API
3. **Workflow Execution** → n8n processa il messaggio
4. **AI Processing** → Chiamate a OpenAI/Claude/altri servizi
5. **Response** → Ritorno tramite HTTP Response
6. **UI Update** → Aggiornamento interfaccia iOS

## Fase 1: Setup n8n e Workflow Base

### 1.1 Installazione n8n

```bash
# Opzione 1: Docker (Raccomandato)
docker run -it --rm \
  --name n8n \
  -p 5678:5678 \
  -v ~/.n8n:/home/node/.n8n \
  n8nio/n8n

# Opzione 2: npm
npm install n8n -g
n8n start
```

### 1.2 Workflow Template per Chat Agent

```json
{
  "name": "AgentChat Workflow",
  "nodes": [
    {
      "parameters": {
        "httpMethod": "POST",
        "path": "chat",
        "responseMode": "responseNode",
        "options": {}
      },
      "id": "webhook-node",
      "name": "Webhook",
      "type": "n8n-nodes-base.webhook",
      "position": [240, 300]
    },
    {
      "parameters": {
        "model": "gpt-4",
        "messages": {
          "messageValues": [
            {
              "role": "user",
              "content": "={{ $json.message }}"
            }
          ]
        }
      },
      "id": "openai-node",
      "name": "OpenAI",
      "type": "@n8n/n8n-nodes-langchain.openAi",
      "position": [460, 300]
    },
    {
      "parameters": {
        "respondWith": "json",
        "responseBody": {
          "response": "={{ $json.choices[0].message.content }}",
          "timestamp": "={{ new Date().toISOString() }}",
          "agent_id": "n8n-agent-1"
        }
      },
      "id": "response-node",
      "name": "Respond to Webhook",
      "type": "n8n-nodes-base.respondToWebhook",
      "position": [680, 300]
    }
  ],
  "connections": {
    "Webhook": {
      "main": [[{"node": "OpenAI", "type": "main", "index": 0}]]
    },
    "OpenAI": {
      "main": [[{"node": "Respond to Webhook", "type": "main", "index": 0}]]
    }
  }
}
```

## Fase 2: Integrazione con Architettura Multi-Provider

### 2.1 Aggiornamento AgentType per n8n

```swift
// Models/AgentType.swift - Estensione per n8n
enum AgentType: String, CaseIterable, Identifiable, Codable {
    // Provider AI esistenti
    case openAI = "OpenAI GPT-4"
    case anthropic = "Anthropic Claude"
    case mistral = "Mistral AI"
    case perplexity = "Perplexity"
    case customProvider = "Custom Provider"
    
    // Agenti n8n specializzati
    case n8nCustomAgent = "n8n Custom Agent"
    case n8nDataAnalyst = "n8n Data Analyst"
    case n8nContentWriter = "n8n Content Writer"
    case n8nCodeReviewer = "n8n Code Reviewer"
    case n8nWorkflowAutomator = "n8n Workflow Automator"
    
    var id: String { rawValue }
    
    var isN8nAgent: Bool {
        switch self {
        case .n8nCustomAgent, .n8nDataAnalyst, .n8nContentWriter, .n8nCodeReviewer, .n8nWorkflowAutomator:
            return true
        default:
            return false
        }
    }
    
    var serviceType: ChatService.Type {
        switch self {
        case .openAI: return OpenAIService.self
        case .anthropic: return AnthropicService.self
        case .mistral: return MistralService.self
        case .perplexity: return PerplexityService.self
        case .customProvider: return CustomProviderService.self
        case .n8nCustomAgent, .n8nDataAnalyst, .n8nContentWriter, .n8nCodeReviewer, .n8nWorkflowAutomator:
            return N8nService.self
        }
    }
    
    var n8nWorkflowId: String? {
        switch self {
        case .n8nCustomAgent: return "workflow-custom"
        case .n8nDataAnalyst: return "workflow-data-analyst"
        case .n8nContentWriter: return "workflow-content-writer"
        case .n8nCodeReviewer: return "workflow-code-reviewer"
        case .n8nWorkflowAutomator: return "workflow-automator"
        default: return nil
        }
    }
    
    var displayIcon: String {
        switch self {
        case .openAI: return "brain.head.profile"
        case .anthropic: return "person.crop.circle"
        case .mistral: return "wind"
        case .perplexity: return "magnifyingglass.circle"
        case .customProvider: return "gear.circle"
        case .n8nCustomAgent: return "flowchart"
        case .n8nDataAnalyst: return "chart.bar.xaxis"
        case .n8nContentWriter: return "doc.text"
        case .n8nCodeReviewer: return "chevron.left.forwardslash.chevron.right"
        case .n8nWorkflowAutomator: return "arrow.triangle.branch"
        }
    }
}
```

### 2.2 Chat Model con Supporto n8n

```swift
// Models/Chat.swift - Estensione per n8n
class Chat: ObservableObject, Identifiable, Equatable {
    let id: UUID
    let agentType: AgentType
    let createdAt: Date
    @Published var messages: [Message]
    
    // Configurazioni specifiche per provider
    private var providerConfig: [String: Any] = [:]
    
    init(id: UUID = UUID(), 
         agentType: AgentType, 
         messages: [Message] = [],
         providerConfig: [String: Any] = [:]) {
        self.id = id
        self.agentType = agentType
        self.createdAt = Date()
        self.messages = messages
        self.providerConfig = providerConfig
    }
    
    // Configurazione OpenAI
    var assistantId: String? {
        get { providerConfig["assistantId"] as? String }
        set { providerConfig["assistantId"] = newValue }
    }
    
    // Configurazione n8n
    var n8nWorkflowId: String? {
        get { providerConfig["n8nWorkflowId"] as? String ?? agentType.n8nWorkflowId }
        set { providerConfig["n8nWorkflowId"] = newValue }
    }
    
    var n8nWebhookUrl: String? {
        get { providerConfig["n8nWebhookUrl"] as? String }
        set { providerConfig["n8nWebhookUrl"] = newValue }
    }
    
    var n8nCustomHeaders: [String: String]? {
        get { providerConfig["n8nCustomHeaders"] as? [String: String] }
        set { providerConfig["n8nCustomHeaders"] = newValue }
    }
    
    // Factory method per il servizio
    var serviceProvider: ChatService {
        if agentType.isN8nAgent {
            return N8nService.shared
        } else {
            return ServiceFactory.createService(for: agentType)
        }
    }
    
    static func == (lhs: Chat, rhs: Chat) -> Bool {
        lhs.id == rhs.id
    }
}
```

## Fase 3: Implementazione N8nService

### 3.1 Integrazione con ChatService Protocol

```swift
// Services/ChatService.swift - Protocollo base già implementato
protocol ChatService {
    func sendMessage(_ message: String, to chatId: UUID) async throws -> String
}

// Estensione per configurazioni n8n specifiche
protocol N8nConfigurable {
    var workflowId: String? { get }
    var webhookUrl: String? { get }
    var customHeaders: [String: String]? { get }
    var timeout: TimeInterval { get }
}

struct N8nConfiguration: N8nConfigurable {
    let workflowId: String?
    let webhookUrl: String?
    let customHeaders: [String: String]?
    let timeout: TimeInterval
    
    init(workflowId: String? = nil, 
         webhookUrl: String? = nil, 
         customHeaders: [String: String]? = nil, 
         timeout: TimeInterval = 30.0) {
        self.workflowId = workflowId
        self.webhookUrl = webhookUrl
        self.customHeaders = customHeaders
        self.timeout = timeout
    }
}
```

### 3.2 N8nService Implementation Completa

```swift
import Foundation

// Modelli di richiesta e risposta aggiornati
struct N8nRequest: Codable {
    let message: String
    let chatId: String
    let timestamp: String
    let userId: String?
    let workflowId: String
    let metadata: [String: String]
    
    // Parametri opzionali per workflow specifici
    let context: N8nContext?
    let preferences: N8nPreferences?
    
    init(message: String, 
         chatId: String, 
         timestamp: String, 
         userId: String?, 
         workflowId: String, 
         metadata: [String: String],
         context: N8nContext? = nil,
         preferences: N8nPreferences? = nil) {
        self.message = message
        self.chatId = chatId
        self.timestamp = timestamp
        self.userId = userId
        self.workflowId = workflowId
        self.metadata = metadata
        self.context = context
        self.preferences = preferences
    }
}

struct N8nContext: Codable {
    let previousMessages: [String]?
    let sessionData: [String: String]?
    let userProfile: [String: String]?
}

struct N8nPreferences: Codable {
    let language: String?
    let responseFormat: String?
    let maxTokens: Int?
    let temperature: Double?
}

struct N8nResponse: Codable {
    let response: String
    let timestamp: String
    let agentId: String
    let workflowId: String
    let executionId: String?
    let metadata: [String: String]?
    let status: N8nExecutionStatus
    let metrics: N8nMetrics?
}

struct N8nExecutionStatus: Codable {
    let success: Bool
    let executionTime: Double?
    let nodeCount: Int?
    let warnings: [String]?
}

struct N8nMetrics: Codable {
    let processingTime: Double
    let tokensUsed: Int?
    let cost: Double?
    let cacheHit: Bool?
}

class N8nService: ChatService {
    static let shared = N8nService()
    
    private let baseURL: String
    private let apiKey: String?
    private let defaultTimeout: TimeInterval
    private var chatConfigurations: [UUID: N8nConfiguration] = [:]
    
    init(baseURL: String = "http://localhost:5678", 
         apiKey: String? = nil, 
         defaultTimeout: TimeInterval = 30.0) {
        self.baseURL = baseURL
        self.apiKey = apiKey
        self.defaultTimeout = defaultTimeout
    }
    
    // Implementazione del protocollo ChatService
    func sendMessage(_ message: String, to chatId: UUID) async throws -> String {
        let config = getChatConfiguration(for: chatId)
        return try await sendMessage(message, to: chatId, with: config)
    }
    
    // Metodo esteso con configurazione personalizzata
    func sendMessage(_ message: String, to chatId: UUID, with config: N8nConfiguration) async throws -> String {
        guard let workflowId = config.workflowId else {
            throw N8nError.missingWorkflowId
        }
        
        let webhookUrl = config.webhookUrl ?? "\(baseURL)/webhook/\(workflowId)"
        
        guard let url = URL(string: webhookUrl) else {
            throw N8nError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = config.timeout
        
        // Headers di autenticazione
        if let apiKey = apiKey {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
        
        // Headers personalizzati
        config.customHeaders?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        let requestBody = N8nRequest(
            message: message,
            chatId: chatId.uuidString,
            timestamp: ISO8601DateFormatter().string(from: Date()),
            userId: "user-\(chatId.uuidString.prefix(8))",
            workflowId: workflowId,
            metadata: createMetadata(for: chatId)
        )
        
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw N8nError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw N8nError.httpError(statusCode: httpResponse.statusCode, message: errorBody)
        }
        
        let n8nResponse = try JSONDecoder().decode(N8nResponse.self, from: data)
        return n8nResponse.response
    }
    
    // Configurazione per chat specifica
    func setChatConfiguration(_ config: N8nConfiguration, for chatId: UUID) {
        chatConfigurations[chatId] = config
    }
    
    private func getChatConfiguration(for chatId: UUID) -> N8nConfiguration {
        return chatConfigurations[chatId] ?? N8nConfiguration(timeout: defaultTimeout)
    }
    
    private func createMetadata(for chatId: UUID) -> [String: String] {
        return [
            "chatId": chatId.uuidString,
            "platform": "iOS",
            "version": "1.0",
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]
    }
}

enum N8nError: LocalizedError {
    case missingWorkflowId
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int, message: String)
    case decodingError(Error)
    case encodingError(Error)
    case timeout
    case workflowExecutionFailed(String)
    case authenticationFailed
    case rateLimitExceeded
    case workflowNotFound(String)
    case invalidConfiguration
    
    var errorDescription: String? {
        switch self {
        case .missingWorkflowId:
            return "Workflow ID mancante per l'agente n8n"
        case .invalidURL:
            return "URL webhook n8n non valido"
        case .invalidResponse:
            return "Risposta non valida dal server n8n"
        case .httpError(let statusCode, let message):
            return "Errore HTTP \(statusCode): \(message)"
        case .decodingError(let error):
            return "Errore nella decodifica della risposta n8n: \(error.localizedDescription)"
        case .encodingError(let error):
            return "Errore nella codifica della richiesta: \(error.localizedDescription)"
        case .timeout:
            return "Timeout nella comunicazione con n8n"
        case .workflowExecutionFailed(let reason):
            return "Esecuzione workflow fallita: \(reason)"
        case .authenticationFailed:
            return "Autenticazione fallita con il server n8n"
        case .rateLimitExceeded:
            return "Limite di richieste superato"
        case .workflowNotFound(let workflowId):
            return "Workflow non trovato: \(workflowId)"
        case .invalidConfiguration:
            return "Configurazione n8n non valida"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .missingWorkflowId:
            return "Verifica che il workflow ID sia configurato correttamente"
        case .invalidURL:
            return "Controlla l'URL del server n8n nelle impostazioni"
        case .authenticationFailed:
            return "Verifica le credenziali API nelle impostazioni"
        case .workflowNotFound:
            return "Assicurati che il workflow sia attivo e pubblicato"
        case .timeout:
            return "Riprova o aumenta il timeout nelle impostazioni"
        default:
            return "Controlla la connessione e riprova"
        }
    }
}
```

## Fase 4: Aggiornamento ChatDetailView

### 4.1 Service Factory Pattern

```swift
class AgentServiceFactory {
    static func createService(for agentType: AgentType) -> AgentServiceProtocol {
        switch agentType {
        case .openAI:
            return OpenAIAssistantService.shared
        case .n8nCustomAgent, .n8nDataAnalyst, .n8nContentWriter, .n8nCodeReviewer:
            return N8nService.shared
        default:
            return MockAgentService() // Per agenti non ancora implementati
        }
    }
}
```

### 4.2 Aggiornamento sendMessage

```swift
// ChatDetailView.swift - Aggiornamento del metodo sendMessage
func sendMessage() async {
    let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty, !isAwaitingAssistant else { return }
    
    let userMsg = Message(id: UUID(), text: trimmed, isUser: true, timestamp: Date())
    chat.messages.append(userMsg)
    inputText = ""
    errorMessage = nil
    isAwaitingAssistant = true
    
    let placeholderId = UUID()
    let placeholderMsg = Message(id: placeholderId, text: "...", isUser: false, timestamp: Date())
    chat.messages.append(placeholderMsg)
    
    do {
        let service = AgentServiceFactory.createService(for: chat.agentType)
        let config = AgentConfig(
            agentType: chat.agentType,
            assistantId: chat.assistantId,
            n8nWorkflowId: chat.n8nWorkflowId,
            n8nWebhookUrl: chat.n8nWebhookUrl
        )
        
        let response = try await service.sendMessage(
            userMessage: trimmed,
            forChat: chat.id,
            withConfig: config
        )
        
        // Rimuovi placeholder
        if let idx = chat.messages.firstIndex(where: { $0.id == placeholderId }) {
            chat.messages.remove(at: idx)
        }
        
        let assistantMessage = Message(id: UUID(), text: response, isUser: false, timestamp: Date())
        chat.messages.append(assistantMessage)
        
    } catch {
        if let idx = chat.messages.firstIndex(where: { $0.id == placeholderId }) {
            chat.messages.remove(at: idx)
        }
        errorMessage = "Errore: \(error.localizedDescription)"
    }
    
    isAwaitingAssistant = false
}
```

## Fase 5: Configurazione Avanzata n8n

### 5.1 Workflow Specializzati

#### Data Analyst Workflow
```json
{
  "name": "Data Analyst Agent",
  "nodes": [
    {
      "name": "Webhook",
      "type": "n8n-nodes-base.webhook"
    },
    {
      "name": "Extract Data Intent",
      "type": "@n8n/n8n-nodes-langchain.openAi",
      "parameters": {
        "model": "gpt-4",
        "messages": {
          "messageValues": [
            {
              "role": "system",
              "content": "You are a data analyst. Analyze the user's request and determine if they need data visualization, statistical analysis, or data processing."
            },
            {
              "role": "user",
              "content": "={{ $json.message }}"
            }
          ]
        }
      }
    },
    {
      "name": "Process Data",
      "type": "n8n-nodes-base.code",
      "parameters": {
        "jsCode": "// Logica di elaborazione dati personalizzata"
      }
    },
    {
      "name": "Generate Response",
      "type": "@n8n/n8n-nodes-langchain.openAi"
    },
    {
      "name": "Respond",
      "type": "n8n-nodes-base.respondToWebhook"
    }
  ]
}
```

#### Content Writer Workflow
```json
{
  "name": "Content Writer Agent",
  "nodes": [
    {
      "name": "Webhook",
      "type": "n8n-nodes-base.webhook"
    },
    {
      "name": "Analyze Content Type",
      "type": "n8n-nodes-base.if",
      "parameters": {
        "conditions": {
          "string": [
            {
              "value1": "={{ $json.message.toLowerCase() }}",
              "operation": "contains",
              "value2": "blog"
            }
          ]
        }
      }
    },
    {
      "name": "Blog Writer",
      "type": "@n8n/n8n-nodes-langchain.openAi",
      "parameters": {
        "model": "gpt-4",
        "messages": {
          "messageValues": [
            {
              "role": "system",
              "content": "You are an expert blog writer. Create engaging, SEO-optimized content."
            }
          ]
        }
      }
    },
    {
      "name": "Social Media Writer",
      "type": "@n8n/n8n-nodes-langchain.openAi",
      "parameters": {
        "model": "gpt-4",
        "messages": {
          "messageValues": [
            {
              "role": "system",
              "content": "You are a social media expert. Create engaging posts for various platforms."
            }
          ]
        }
      }
    }
  ]
}
```

### 5.2 Gestione Configurazioni

```swift
struct N8nConfiguration {
    let baseURL: String
    let apiKey: String?
    let workflows: [String: N8nWorkflow]
    
    static let `default` = N8nConfiguration(
        baseURL: "http://localhost:5678",
        apiKey: nil,
        workflows: [
            "data-analyst": N8nWorkflow(
                id: "workflow-2",
                name: "Data Analyst",
                webhookPath: "/webhook/data-analyst",
                description: "Analizza dati e crea visualizzazioni"
            ),
            "content-writer": N8nWorkflow(
                id: "workflow-3",
                name: "Content Writer",
                webhookPath: "/webhook/content-writer",
                description: "Crea contenuti per blog e social media"
            )
        ]
    )
}

struct N8nWorkflow {
    let id: String
    let name: String
    let webhookPath: String
    let description: String
}
```

## Fase 6: UI per Configurazione n8n

### 6.1 N8nConfigurationView

```swift
struct N8nConfigurationView: View {
    @State private var baseURL = "http://localhost:5678"
    @State private var apiKey = ""
    @State private var testConnection = false
    @State private var connectionStatus: ConnectionStatus = .unknown
    
    enum ConnectionStatus {
        case unknown, testing, success, failed
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Configurazione Server n8n") {
                    TextField("URL Base", text: $baseURL)
                        .textFieldStyle(.roundedBorder)
                    
                    SecureField("API Key (opzionale)", text: $apiKey)
                        .textFieldStyle(.roundedBorder)
                    
                    Button("Testa Connessione") {
                        Task { await testN8nConnection() }
                    }
                    .disabled(connectionStatus == .testing)
                    
                    HStack {
                        Text("Stato:")
                        Spacer()
                        connectionStatusView
                    }
                }
                
                Section("Workflow Disponibili") {
                    ForEach(availableWorkflows, id: \.id) { workflow in
                        WorkflowRowView(workflow: workflow)
                    }
                }
            }
            .navigationTitle("Configurazione n8n")
        }
    }
    
    @ViewBuilder
    private var connectionStatusView: some View {
        switch connectionStatus {
        case .unknown:
            Text("Non testato")
                .foregroundColor(.gray)
        case .testing:
            ProgressView()
                .scaleEffect(0.8)
        case .success:
            Label("Connesso", systemImage: "checkmark.circle")
                .foregroundColor(.green)
        case .failed:
            Label("Errore", systemImage: "xmark.circle")
                .foregroundColor(.red)
        }
    }
    
    private func testN8nConnection() async {
        connectionStatus = .testing
        
        do {
            let service = N8nService(baseURL: baseURL, apiKey: apiKey.isEmpty ? nil : apiKey)
            // Test con un workflow di prova
            _ = try await service.sendMessage(
                userMessage: "test",
                forChat: UUID(),
                withConfig: AgentConfig(
                    agentType: .n8nCustomAgent,
                    assistantId: nil,
                    n8nWorkflowId: "test",
                    n8nWebhookUrl: nil
                )
            )
            connectionStatus = .success
        } catch {
            connectionStatus = .failed
        }
    }
}
```

## Fase 7: Gestione Errori e Fallback

### 7.1 Retry Logic

```swift
class N8nServiceWithRetry: N8nService {
    private let maxRetries = 3
    private let retryDelay: TimeInterval = 1.0
    
    override func sendMessage(userMessage: String, forChat chatId: UUID, withConfig config: AgentConfig) async throws -> String {
        var lastError: Error?
        
        for attempt in 0..<maxRetries {
            do {
                return try await super.sendMessage(userMessage: userMessage, forChat: chatId, withConfig: config)
            } catch {
                lastError = error
                
                if attempt < maxRetries - 1 {
                    try await Task.sleep(nanoseconds: UInt64(retryDelay * Double(attempt + 1) * 1_000_000_000))
                }
            }
        }
        
        throw lastError ?? N8nError.decodingError
    }
}
```

### 7.2 Fallback Service

```swift
class FallbackAgentService: AgentServiceProtocol {
    private let primaryService: AgentServiceProtocol
    private let fallbackService: AgentServiceProtocol
    
    init(primary: AgentServiceProtocol, fallback: AgentServiceProtocol) {
        self.primaryService = primary
        self.fallbackService = fallback
    }
    
    func sendMessage(userMessage: String, forChat chatId: UUID, withConfig config: AgentConfig) async throws -> String {
        do {
            return try await primaryService.sendMessage(userMessage: userMessage, forChat: chatId, withConfig: config)
        } catch {
            print("Primary service failed, trying fallback: \(error)")
            return try await fallbackService.sendMessage(userMessage: userMessage, forChat: chatId, withConfig: config)
        }
    }
}
```

## Roadmap di Implementazione

### ✅ Fase Completata - Architettura Base
- [x] Implementazione protocollo ChatService
- [x] Creazione modelli dati strutturati (Chat, Message, AgentType)
- [x] Implementazione ServiceFactory pattern
- [x] Estensione AgentType per supporto n8n
- [x] Aggiornamento Chat model con configurazioni provider
- [x] Implementazione N8nService base con ChatService protocol
- [x] Modelli di richiesta/risposta N8n completi
- [x] Sistema di gestione errori unificato

### 🚧 Sprint 1 - Setup e Testing Base (1-2 settimane)
- [ ] Setup ambiente n8n locale con Docker
- [ ] Creazione workflow base per test di connettività
- [ ] Implementazione sistema di configurazione N8n
- [ ] Test di integrazione N8nService con workflow semplice
- [ ] Validazione protocollo di comunicazione

### 📋 Sprint 2 - Integrazione UI (1-2 settimane)
- [ ] Aggiornamento ContentView per supporto agenti n8n
- [ ] Implementazione N8nConfigurationView
- [ ] Integrazione ServiceFactory in ChatDetailView
- [ ] UI per selezione e configurazione workflow
- [ ] Test di usabilità e flusso utente

### 🔧 Sprint 3 - Workflow Specializzati (2-3 settimane)
- [ ] Creazione workflow Data Analyst con visualizzazioni
- [ ] Implementazione workflow Content Writer multi-formato
- [ ] Sviluppo workflow Code Reviewer con analisi statica
- [ ] Workflow Automator per task complessi
- [ ] Sistema di template workflow riutilizzabili

### ⚡ Sprint 4 - Ottimizzazioni e Produzione (2-3 settimane)
- [ ] Implementazione retry logic e fallback
- [ ] Sistema di caching per risposte frequenti
- [ ] Monitoring e metriche di performance
- [ ] Gestione configurazioni ambiente (dev/prod)
- [ ] Documentazione tecnica e user guide

### 🔮 Roadmap Futura
- [ ] Supporto workflow dinamici creati dall'utente
- [ ] Integrazione con database esterni tramite n8n
- [ ] Sistema di notifiche push per workflow asincroni
- [ ] Analytics e insights sull'utilizzo dei workflow
- [ ] Marketplace di workflow condivisi

## Vantaggi dell'Integrazione n8n

✅ **Flessibilità**: Workflow personalizzabili per ogni caso d'uso
✅ **Scalabilità**: Gestione di più agenti specializzati
✅ **Integrazione**: Connessione con servizi esterni (database, API, etc.)
✅ **Visual Workflow**: Interfaccia grafica per creare e modificare agenti
✅ **Monitoring**: Tracciamento esecuzioni e performance
✅ **Community**: Ampia libreria di nodi e integrazioni

## Considerazioni Tecniche

### Sicurezza
- Autenticazione API key per n8n
- Validazione input per prevenire injection
- Rate limiting per evitare abuse

### Performance
- Timeout configurabili per workflow lunghi
- Caching delle risposte frequenti
- Connection pooling per HTTP requests

### Monitoring
- Logging delle richieste e risposte
- Metriche di performance
- Alerting per errori critici

Questa integrazione trasformerà AgentChat in una piattaforma potente e flessibile per interagire con agenti AI personalizzati tramite n8n.