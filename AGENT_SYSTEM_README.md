# Sistema di Agenti Avanzato - AgentChat

Questo documento descrive il nuovo sistema di agenti implementato in AgentChat, che supporta agenti singoli, multi-agente e collaborazione avanzata.

## Panoramica

Il sistema di agenti è stato progettato per fornire:

- **Agenti Singoli**: Interazione con un singolo provider AI
- **Multi-Agente**: Coordinazione tra più agenti per task complessi
- **Memoria Conversazionale**: Gestione del contesto tra le conversazioni
- **Collaborazione**: Agenti che lavorano insieme su task specifici
- **Estensibilità**: Supporto per provider personalizzati

## Architettura

### Componenti Principali

1. **BaseAgentService**: Classe base per tutti i servizi agente
2. **AgentOrchestrator**: Gestisce la coordinazione tra agenti
3. **AgentConfiguration**: Configurazione degli agenti
4. **ServiceFactory**: Factory per creare servizi agente
5. **ChatManager**: Interfaccia principale per l'utilizzo

### Provider Supportati

- **OpenAI**: GPT-4, GPT-3.5-turbo
- **Anthropic**: Claude-3.5-sonnet, Claude-3-haiku
- **Mistral**: Mistral-large, Mistral-medium
- **Perplexity**: Modelli con ricerca web
- **Grok**: Modelli X.AI
- **N8N**: Workflow di automazione
- **Custom**: Provider personalizzati

## Utilizzo Base

### Agente Singolo

```swift
// Crea una configurazione
let config = AgentConfiguration.createAgentConfiguration(
    name: "Assistente Programmazione",
    agentType: .openAI,
    model: "gpt-4",
    systemPrompt: "Sei un esperto programmatore Swift.",
    capabilities: [.textGeneration, .codeGeneration, .reasoning]
)

// Ottieni il servizio
guard let agentService = ChatManager.shared.getAgentService(for: config) else {
    return
}

// Invia un messaggio
let response = try await agentService.sendMessage(
    "Scrivi una funzione per ordinare un array",
    context: []
)
```

### Multi-Agente

```swift
let orchestrator = ChatManager.shared.getAgentOrchestrator()

// Configura gli agenti
let researcher = AgentConfiguration.createAgentConfiguration(
    name: "Ricercatore",
    agentType: .perplexity,
    systemPrompt: "Raccogli informazioni accurate."
)

let analyst = AgentConfiguration.createAgentConfiguration(
    name: "Analista",
    agentType: .anthropic,
    systemPrompt: "Analizza e fornisci insight."
)

// Crea sessione
let sessionId = orchestrator.createSession(
    type: .multiAgent,
    configurations: [researcher, analyst],
    taskType: .sequential
)

// Esegui task collaborativo
let result = try await orchestrator.processMessage(
    sessionId: sessionId!,
    message: "Analizza le tendenze del mercato AI",
    context: []
)
```

## Configurazione Agenti

### Parametri Base

```swift
struct AgentConfiguration {
    let id: UUID
    var name: String
    var systemPrompt: String
    var agentType: AgentType
    var model: String
    var capabilities: Set<AgentCapability>
    var parameters: AgentParameters
    // ... altri parametri
}
```

### Parametri Avanzati

```swift
struct AgentParameters {
    let temperature: Double        // 0.0 - 2.0
    let maxTokens: Int?           // Limite token
    let topP: Double?             // Nucleus sampling
    let frequencyPenalty: Double? // Penalità frequenza
    let presencePenalty: Double?  // Penalità presenza
    let stopSequences: [String]?  // Sequenze di stop
    let timeout: TimeInterval     // Timeout richiesta
    let retryAttempts: Int        // Tentativi di retry
}
```

### Capacità Agenti

```swift
enum AgentCapability {
    case textGeneration    // Generazione testo
    case codeGeneration   // Generazione codice
    case webSearch        // Ricerca web
    case dataAnalysis     // Analisi dati
    case creative         // Creatività
    case reasoning        // Ragionamento
    case conversational   // Conversazione
    case taskManagement   // Gestione task
    case automation       // Automazione
    case qualityAssurance // Quality assurance
}
```

## Tipi di Task Multi-Agente

### Sequential
Gli agenti lavorano in sequenza, passando il risultato al successivo.

```swift
let sessionId = orchestrator.createSession(
    type: .multiAgent,
    configurations: [agent1, agent2, agent3],
    taskType: .sequential
)
```

### Parallel
Gli agenti lavorano in parallelo sullo stesso task.

```swift
let sessionId = orchestrator.createSession(
    type: .multiAgent,
    configurations: [agent1, agent2, agent3],
    taskType: .parallel
)
```

### Collaborative
Gli agenti collaborano dinamicamente.

```swift
let sessionId = orchestrator.createSession(
    type: .multiAgent,
    configurations: [agent1, agent2, agent3],
    taskType: .collaborative
)
```

## Gestione Memoria

### Salvataggio Contesto

```swift
let context = ConversationContext(
    agentId: config.id.uuidString,
    messages: messages,
    metadata: ["session_type": "research"]
)

try await agentService.saveConversationContext(context)
```

### Caricamento Contesto

```swift
let savedContext = try await agentService.loadConversationContext(
    agentId: config.id.uuidString
)
```

### Pulizia Memoria

```swift
try await agentService.clearConversationMemory(
    agentId: config.id.uuidString
)
```

## Provider Personalizzati

### Configurazione Custom

```swift
var customConfig = AgentConfiguration.createAgentConfiguration(
    name: "Provider Personalizzato",
    agentType: .custom
)

customConfig.customConfig = [
    "api_endpoint": "https://api.custom.com/v1/chat",
    "api_key": "your-api-key",
    "model_name": "custom-model",
    "format": "openai" // o "anthropic" o "custom"
]
```

## Integrazione N8N

### Workflow Automation

```swift
let n8nService = agentService as? N8NAgentService

// Esegui workflow
let result = try await n8nService?.executeWorkflow(
    workflowId: "data-processing",
    input: ["data": jsonData]
)

// Lista workflow
let workflows = try await n8nService?.listWorkflows()
```

## Gestione Errori

### Tipi di Errore

```swift
enum AgentServiceError: Error {
    case invalidConfiguration(String)
    case networkError(String)
    case authenticationError(String)
    case rateLimitExceeded(String)
    case modelNotSupported(String)
    case memoryError(String)
    case collaborationError(String)
}
```

### Gestione

```swift
do {
    let response = try await agentService.sendMessage(message, context: [])
} catch let error as AgentServiceError {
    switch error {
    case .invalidConfiguration(let msg):
        print("Configurazione non valida: \(msg)")
    case .networkError(let msg):
        print("Errore di rete: \(msg)")
    // ... altri casi
    }
}
```

## Best Practices

### 1. Configurazione Agenti

- Usa system prompt specifici e dettagliati
- Imposta temperature appropriate (0.3 per codice, 0.7-0.9 per creatività)
- Limita maxTokens per controllare i costi
- Configura timeout appropriati

### 2. Multi-Agente

- Usa agenti specializzati per task specifici
- Scegli il tipo di task appropriato (sequential/parallel/collaborative)
- Monitora le performance e i costi
- Gestisci le sessioni (crea/usa/termina)

### 3. Memoria

- Salva contesto per conversazioni lunghe
- Pulisci memoria periodicamente
- Usa metadata per organizzare i contesti

### 4. Errori

- Implementa retry logic appropriato
- Gestisci rate limiting
- Valida configurazioni prima dell'uso
- Log errori per debugging

## Esempi Completi

Vedi il file `AgentSystemExamples.swift` per esempi completi di:

- Agenti singoli
- Collaborazione multi-agente
- Gestione memoria
- Provider personalizzati
- Workflow N8N
- Gestione errori
- Monitoraggio performance

## Migrazione dal Sistema Precedente

Il nuovo sistema mantiene compatibilità con l'API esistente:

```swift
// Vecchio modo (ancora supportato)
let service = ChatManager.shared.getChatService(for: .openAI)

// Nuovo modo (raccomandato)
let agentService = ChatManager.shared.getAgentService(for: configuration)
```

## Performance e Costi

### Monitoraggio

- Usa timeout appropriati
- Monitora il numero di token
- Traccia le chiamate API
- Implementa caching quando possibile

### Ottimizzazione

- Riutilizza sessioni quando possibile
- Usa agenti appropriati per task specifici
- Implementa fallback per errori
- Considera l'uso di modelli più economici per task semplici

## Supporto e Debugging

### Log

Il sistema include logging dettagliato per:

- Creazione agenti
- Invio messaggi
- Errori di rete
- Performance

### Debug

- Usa `AgentExamplesRunner.runAllExamples()` per testare
- Verifica configurazioni con `validate()`
- Monitora sessioni attive
- Controlla memoria utilizzata

## Roadmap

### Funzionalità Future

- [ ] Streaming responses
- [ ] Plugin system
- [ ] Advanced memory management
- [ ] Performance analytics
- [ ] Cost tracking
- [ ] Agent marketplace
- [ ] Visual workflow builder
- [ ] Real-time collaboration

---

**Nota**: Questo sistema è in continua evoluzione. Consulta la documentazione aggiornata e gli esempi per le ultime funzionalità.