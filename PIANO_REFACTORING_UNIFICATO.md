# Piano di Refactoring Unificato - AgentChat Multi-Agente Collaborativo

## 🎯 Visione del Sistema

**Obiettivo**: Creare un sistema di agenti AI configurabili che possano collaborare tra loro per completare task complessi, con un'architettura pulita, modulare e facilmente estensibile.

**Caso d'Uso Principale**: 
> "Voglio scrivere un post LinkedIn su un tema. Perplexity ricerca i trend, io scelgo il tema, Perplexity approfondisce la ricerca, Claude scrive il post, e un agente N8N lo pubblica automaticamente - tutto in una chat di gruppo collaborativa."

---

## 🏗️ Architettura Target

### Core Components
```
┌─────────────────────────────────────────────────────────────┐
│                    AgentChat iOS App                        │
├─────────────────────────────────────────────────────────────┤
│  UI Layer (SwiftUI)                                        │
│  ├── ChatDetailView (Single & Group)                       │
│  ├── AgentConfigurationView                                │
│  └── GroupChatView (WhatsApp-style)                        │
├─────────────────────────────────────────────────────────────┤
│  Business Logic Layer                                       │
│  ├── AgentOrchestrator (Task Coordination)                 │
│  ├── ConversationEngine (Multi-Agent Flow)                 │
│  └── TaskExecutor (Workflow Management)                     │
├─────────────────────────────────────────────────────────────┤
│  Service Layer                                              │
│  ├── BaseAgentService (Unified Interface)                  │
│  ├── ConfigurableAgentService                              │
│  ├── GroupChatService                                      │
│  └── N8NIntegrationService                                 │
├─────────────────────────────────────────────────────────────┤
│  Data Layer                                                 │
│  ├── AgentConfigurationManager                             │
│  ├── ConversationMemoryManager                             │
│  └── TaskHistoryManager                                    │
└─────────────────────────────────────────────────────────────┘
```

---

## 📋 Roadmap Implementazione (8 Settimane)

### **Fase 1: Refactoring Architetturale (Settimana 1-2)**

#### 1.1 Unificazione Servizi AI
**Problema**: Duplicazione massiva di codice tra OpenAI, Claude, Mistral, etc.

**Soluzione**: Base Service Pattern
```swift
// Services/BaseAgentService.swift
protocol AgentServiceProtocol {
    var providerName: String { get }
    var supportedModels: [String] { get }
    func sendMessage(_ message: String, configuration: AgentConfiguration) async throws -> String
    func validateConfiguration(_ config: AgentConfiguration) async throws -> Bool
}

abstract class BaseAgentService: AgentServiceProtocol {
    // Logica comune HTTP, error handling, retry logic
    private let httpClient: HTTPClient
    private let errorHandler: ErrorHandler
    private let retryManager: RetryManager
    
    // Template method pattern
    final func sendMessage(_ message: String, configuration: AgentConfiguration) async throws -> String {
        try await validateConfiguration(configuration)
        let request = buildRequest(message, configuration)
        let response = try await httpClient.send(request)
        return parseResponse(response)
    }
    
    // Abstract methods da implementare
    abstract func buildRequest(_ message: String, _ config: AgentConfiguration) -> HTTPRequest
    abstract func parseResponse(_ response: HTTPResponse) -> String
}
```

#### 1.2 Modello Agente Unificato
```swift
// Models/AgentConfiguration.swift
struct AgentConfiguration: Identifiable, Codable {
    let id: UUID
    var name: String
    var role: String
    var systemPrompt: String
    var personality: String
    var icon: String
    
    // Provider Configuration
    var providerType: ProviderType
    var modelName: String
    var temperature: Double
    var maxTokens: Int
    
    // Collaboration Settings
    var canInitiateConversations: Bool
    var preferredCollaborators: [UUID]
    var specializations: [String]
    
    // Memory & Context
    var memoryEnabled: Bool
    var contextWindow: Int
    var retainConversationHistory: Bool
    
    // N8N Integration
    var n8nWorkflowId: String?
    var automationCapabilities: [AutomationCapability]
    
    enum ProviderType: String, CaseIterable {
        case openAI = "OpenAI"
        case anthropic = "Anthropic"
        case mistral = "Mistral"
        case perplexity = "Perplexity"
        case grok = "Grok"
        case n8n = "N8N"
        case custom = "Custom"
    }
    
    enum AutomationCapability: String, CaseIterable {
        case webSearch = "Web Search"
        case contentGeneration = "Content Generation"
        case dataAnalysis = "Data Analysis"
        case socialMediaPosting = "Social Media Posting"
        case emailSending = "Email Sending"
        case fileProcessing = "File Processing"
    }
}
```

### **Fase 2: Sistema Multi-Agente Collaborativo (Settimana 3-4)**

#### 2.1 Agent Orchestrator
```swift
// Services/AgentOrchestrator.swift
class AgentOrchestrator: ObservableObject {
    @Published var activeConversations: [GroupConversation] = []
    
    private let conversationEngine = ConversationEngine()
    private let taskPlanner = TaskPlanner()
    private let agentSelector = AgentSelector()
    
    func startCollaborativeTask(_ task: CollaborativeTask) async {
        // 1. Analizza il task e identifica gli agenti necessari
        let requiredAgents = await taskPlanner.identifyRequiredAgents(for: task)
        
        // 2. Crea una conversazione di gruppo
        let conversation = GroupConversation(
            task: task,
            participants: requiredAgents,
            orchestrator: self
        )
        
        // 3. Avvia la conversazione collaborativa
        await conversationEngine.startConversation(conversation)
        
        await MainActor.run {
            activeConversations.append(conversation)
        }
    }
    
    func handleTaskCompletion(_ conversation: GroupConversation) {
        // Gestisce il completamento del task e cleanup
    }
}

// Models/CollaborativeTask.swift
struct CollaborativeTask: Identifiable {
    let id: UUID
    let title: String
    let description: String
    let steps: [TaskStep]
    let expectedOutcome: String
    let priority: Priority
    
    enum Priority {
        case low, medium, high, urgent
    }
}

struct TaskStep: Identifiable {
    let id: UUID
    let description: String
    let requiredCapabilities: [AgentConfiguration.AutomationCapability]
    let dependsOn: [UUID]? // Altri step
    let estimatedDuration: TimeInterval
}
```

#### 2.2 Conversation Engine
```swift
// Services/ConversationEngine.swift
class ConversationEngine {
    private let messageRouter = MessageRouter()
    private let contextManager = ConversationContextManager()
    
    func startConversation(_ conversation: GroupConversation) async {
        var currentStep = 0
        let maxSteps = conversation.task.steps.count * 2 // Safety limit
        
        while currentStep < maxSteps && !conversation.isCompleted {
            // 1. Determina il prossimo agente che deve parlare
            let nextAgent = await selectNextAgent(conversation)
            
            // 2. Prepara il contesto per l'agente
            let context = await contextManager.buildContext(for: nextAgent, in: conversation)
            
            // 3. Genera la risposta dell'agente
            let response = try await nextAgent.generateResponse(context: context)
            
            // 4. Processa la risposta e aggiorna la conversazione
            await processAgentResponse(response, from: nextAgent, in: conversation)
            
            // 5. Verifica se il task è completato
            if await checkTaskCompletion(conversation) {
                await finalizeConversation(conversation)
                break
            }
            
            currentStep += 1
            
            // Pausa realistica tra messaggi
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 secondi
        }
    }
    
    private func selectNextAgent(_ conversation: GroupConversation) async -> AgentConfiguration {
        // Logica intelligente per selezionare il prossimo agente
        // basata su: task step corrente, ultimo agente, capabilities richieste
    }
}
```

### **Fase 3: Integrazione N8N e Automazione (Settimana 5-6)**

#### 3.1 N8N Service Integration
```swift
// Services/N8NIntegrationService.swift
class N8NIntegrationService: BaseAgentService {
    private let baseURL: String
    private let apiKey: String
    
    override var providerName: String { "N8N Automation" }
    override var supportedModels: [String] { ["workflow-executor"] }
    
    func executeWorkflow(
        workflowId: String, 
        input: [String: Any],
        configuration: AgentConfiguration
    ) async throws -> WorkflowResult {
        let endpoint = "\(baseURL)/webhook/\(workflowId)"
        
        let request = HTTPRequest(
            url: endpoint,
            method: .POST,
            headers: ["Authorization": "Bearer \(apiKey)"],
            body: try JSONSerialization.data(withJSONObject: input)
        )
        
        let response = try await httpClient.send(request)
        return try JSONDecoder().decode(WorkflowResult.self, from: response.data)
    }
    
    // Implementazione per automazioni specifiche
    func publishToLinkedIn(_ content: String) async throws -> Bool {
        let input = [
            "content": content,
            "platform": "linkedin",
            "action": "publish"
        ]
        
        let result = try await executeWorkflow(
            workflowId: "linkedin-publisher",
            input: input,
            configuration: AgentConfiguration.linkedInPublisher
        )
        
        return result.success
    }
}

struct WorkflowResult: Codable {
    let success: Bool
    let data: [String: Any]?
    let error: String?
    let executionId: String
    let timestamp: Date
}
```

#### 3.2 Agenti Specializzati Pre-configurati
```swift
// Models/PreConfiguredAgents.swift
extension AgentConfiguration {
    // Agente per ricerca trend
    static let trendResearcher = AgentConfiguration(
        id: UUID(),
        name: "Trend Researcher",
        role: "Ricercatore di Tendenze",
        systemPrompt: "Sei un esperto ricercatore di tendenze. Analizza i trend attuali e fornisci insights dettagliati sui temi più rilevanti.",
        personality: "Analitico, aggiornato, orientato ai dati",
        icon: "📈",
        providerType: .perplexity,
        modelName: "perplexity-online",
        temperature: 0.3,
        maxTokens: 2000,
        canInitiateConversations: true,
        specializations: ["trend analysis", "market research", "social listening"]
    )
    
    // Agente per scrittura contenuti
    static let contentWriter = AgentConfiguration(
        id: UUID(),
        name: "Content Writer",
        role: "Scrittore di Contenuti",
        systemPrompt: "Sei un copywriter esperto specializzato in contenuti per social media. Scrivi sempre contenuti coinvolgenti, autentici e ottimizzati per la piattaforma target.",
        personality: "Creativo, persuasivo, orientato al pubblico",
        icon: "✍️",
        providerType: .anthropic,
        modelName: "claude-3-sonnet",
        temperature: 0.7,
        maxTokens: 1500,
        specializations: ["copywriting", "social media", "content strategy"]
    )
    
    // Agente per automazione pubblicazione
    static let socialMediaPublisher = AgentConfiguration(
        id: UUID(),
        name: "Social Media Publisher",
        role: "Gestore Pubblicazioni",
        systemPrompt: "Sei responsabile della pubblicazione automatica di contenuti sui social media. Ottimizzi timing, hashtag e formato per massimizzare l'engagement.",
        personality: "Efficiente, strategico, orientato ai risultati",
        icon: "📱",
        providerType: .n8n,
        n8nWorkflowId: "social-media-publisher",
        automationCapabilities: [.socialMediaPosting],
        specializations: ["social media management", "automation", "scheduling"]
    )
}
```

### **Fase 4: UI Multi-Agente e Chat Singole (Settimana 7)**

#### 4.1 Single Agent Chat Support
**Nuova Funzionalità**: Chat dirette con singoli agenti configurabili

```swift
// Views/SingleAgentChatView.swift
struct SingleAgentChatView: View {
    @ObservedObject var chat: Chat
    @State private var agent: AgentConfiguration
    @State private var userInput = ""
    @State private var showingAgentConfig = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Agent Header
            SingleAgentHeader(
                agent: agent,
                onConfigTap: { showingAgentConfig = true }
            )
            
            // Messages List
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(chat.messages) { message in
                            MessageBubble(
                                message: message,
                                agent: agent
                            )
                            .id(message.id)
                        }
                    }
                    .padding(.horizontal)
                }
                .onChange(of: chat.messages.count) { _ in
                    if let lastMessage = chat.messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            // Input Area
            ChatInputView(
                text: $userInput,
                onSend: sendMessage,
                placeholder: "Messaggio per \(agent.name)..."
            )
        }
        .navigationTitle(agent.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Configura") {
                    showingAgentConfig = true
                }
            }
        }
        .sheet(isPresented: $showingAgentConfig) {
            AgentConfigurationView(agent: $agent)
        }
    }
    
    private func sendMessage() {
        guard !userInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        Task {
            await chat.sendMessage(userInput, to: agent)
            userInput = ""
        }
    }
}

// Views/AgentSelectionView.swift
struct AgentSelectionView: View {
    @ObservedObject var agentManager = AgentConfigurationManager.shared
    @State private var showingCreateAgent = false
    
    let onAgentSelected: (AgentConfiguration) -> Void
    
    var body: some View {
        NavigationView {
            List {
                // Quick Access: OpenAI Default
                Section("Accesso Rapido") {
                    AgentQuickAccessRow(
                        title: "OpenAI Assistant",
                        subtitle: "Chat diretta con GPT-4",
                        icon: "🤖",
                        agent: .openAIDefault
                    ) {
                        onAgentSelected(.openAIDefault)
                    }
                }
                
                // Custom Agents
                Section("Agenti Personalizzati") {
                    ForEach(agentManager.customAgents) { agent in
                        AgentSelectionRow(agent: agent) {
                            onAgentSelected(agent)
                        }
                    }
                }
                
                // Predefined Agents
                Section("Agenti Predefiniti") {
                    ForEach(AgentConfiguration.predefinedAgents) { agent in
                        AgentSelectionRow(agent: agent) {
                            onAgentSelected(agent)
                        }
                    }
                }
            }
            .navigationTitle("Scegli Agente")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Nuovo") {
                        showingCreateAgent = true
                    }
                }
            }
            .sheet(isPresented: $showingCreateAgent) {
                CreateAgentView { newAgent in
                    agentManager.addAgent(newAgent)
                    onAgentSelected(newAgent)
                }
            }
        }
    }
}
```

#### 4.2 Enhanced Chat Types
```swift
// Models/ChatType.swift
enum ChatType: String, CaseIterable {
    case singleAgent = "single_agent"
    case groupCollaborative = "group_collaborative"
    case openAIDefault = "openai_default"
    
    var displayName: String {
        switch self {
        case .singleAgent:
            return "Chat con Agente"
        case .groupCollaborative:
            return "Task Collaborativo"
        case .openAIDefault:
            return "OpenAI Assistant"
        }
    }
    
    var icon: String {
        switch self {
        case .singleAgent:
            return "person.circle"
        case .groupCollaborative:
            return "person.3"
        case .openAIDefault:
            return "brain"
        }
    }
}

// Extension per AgentConfiguration
extension AgentConfiguration {
    static let openAIDefault = AgentConfiguration(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
        name: "OpenAI Assistant",
        role: "Assistente Generale",
        systemPrompt: "Sei un assistente AI utile, accurato e conciso.",
        personality: "Professionale, disponibile, preciso",
        icon: "🤖",
        providerType: .openAI,
        modelName: "gpt-4",
        temperature: 0.7,
        maxTokens: 2000,
        canInitiateConversations: false,
        specializations: ["general assistance", "Q&A", "problem solving"]
    )
    
    static let predefinedAgents: [AgentConfiguration] = [
        .trendResearcher,
        .contentWriter,
        .socialMediaPublisher,
        .dataAnalyst,
        .codeReviewer,
        .creativeWriter
    ]
}
```

#### 4.3 Updated New Chat Flow
```swift
// Views/NewChatView.swift
struct NewChatView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedChatType: ChatType = .singleAgent
    @State private var showingAgentSelection = false
    @State private var showingTaskCreator = false
    
    let onChatCreated: (Chat) -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("Che tipo di conversazione vuoi iniziare?")
                    .font(.title2)
                    .multilineTextAlignment(.center)
                    .padding(.top)
                
                VStack(spacing: 16) {
                    // OpenAI Quick Start
                    ChatTypeCard(
                        type: .openAIDefault,
                        description: "Chat veloce con GPT-4"
                    ) {
                        createOpenAIChat()
                    }
                    
                    // Single Agent Chat
                    ChatTypeCard(
                        type: .singleAgent,
                        description: "Conversa con un agente specializzato"
                    ) {
                        showingAgentSelection = true
                    }
                    
                    // Collaborative Task
                    ChatTypeCard(
                        type: .groupCollaborative,
                        description: "Task complesso con più agenti"
                    ) {
                        showingTaskCreator = true
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Nuova Conversazione")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") { dismiss() }
                }
            }
        }
        .sheet(isPresented: $showingAgentSelection) {
            AgentSelectionView { agent in
                createSingleAgentChat(with: agent)
                showingAgentSelection = false
            }
        }
        .sheet(isPresented: $showingTaskCreator) {
            TaskCreatorView { task in
                createCollaborativeChat(for: task)
                showingTaskCreator = false
            }
        }
    }
    
    private func createOpenAIChat() {
        let chat = Chat(
            id: UUID(),
            title: "OpenAI Assistant",
            type: .openAIDefault,
            agentConfiguration: .openAIDefault,
            messages: [],
            createdAt: Date()
        )
        onChatCreated(chat)
        dismiss()
    }
    
    private func createSingleAgentChat(with agent: AgentConfiguration) {
        let chat = Chat(
            id: UUID(),
            title: "Chat con \(agent.name)",
            type: .singleAgent,
            agentConfiguration: agent,
            messages: [],
            createdAt: Date()
        )
        onChatCreated(chat)
        dismiss()
    }
    
    private func createCollaborativeChat(for task: CollaborativeTask) {
        let chat = Chat(
            id: UUID(),
            title: task.title,
            type: .groupCollaborative,
            collaborativeTask: task,
            messages: [],
            createdAt: Date()
        )
        onChatCreated(chat)
        dismiss()
    }
}
```

#### 4.4 Group Chat View (Stile WhatsApp)
```swift
// Views/GroupChatView.swift
struct GroupChatView: View {
    @ObservedObject var conversation: GroupConversation
    @State private var userInput = ""
    @State private var showingTaskCreator = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header con partecipanti
            GroupChatHeader(participants: conversation.participants)
            
            // Task Progress Indicator
            if conversation.isActive {
                TaskProgressView(task: conversation.task)
            }
            
            // Messages List
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(conversation.messages) { message in
                            GroupMessageBubble(message: message)
                                .id(message.id)
                        }
                        
                        // Typing indicators
                        if let typingAgent = conversation.currentlyTyping {
                            TypingIndicatorView(agent: typingAgent)
                        }
                    }
                    .padding(.horizontal)
                }
                .onChange(of: conversation.messages.count) { _ in
                    if let lastMessage = conversation.messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            // Input Area
            GroupChatInputView(
                text: $userInput,
                onSend: sendMessage,
                onCreateTask: { showingTaskCreator = true }
            )
        }
        .navigationTitle(conversation.task.title)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingTaskCreator) {
            TaskCreatorView { task in
                Task {
                    await conversation.addTask(task)
                }
            }
        }
    }
    
    private func sendMessage() {
        guard !userInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        Task {
            await conversation.addUserMessage(userInput)
            userInput = ""
        }
    }
}
```

#### 4.2 Task Creator Interface
```swift
// Views/TaskCreatorView.swift
struct TaskCreatorView: View {
    @State private var taskTitle = ""
    @State private var taskDescription = ""
    @State private var selectedTemplate: TaskTemplate?
    @Environment(\.dismiss) private var dismiss
    
    let onTaskCreated: (CollaborativeTask) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section("Task Details") {
                    TextField("Titolo del task", text: $taskTitle)
                    TextField("Descrizione", text: $taskDescription, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Template Predefiniti") {
                    ForEach(TaskTemplate.predefined) { template in
                        TaskTemplateRow(
                            template: template,
                            isSelected: selectedTemplate?.id == template.id
                        )
                        .onTapGesture {
                            selectedTemplate = template
                            taskTitle = template.title
                            taskDescription = template.description
                        }
                    }
                }
                
                if let template = selectedTemplate {
                    Section("Agenti Coinvolti") {
                        ForEach(template.requiredAgents) { agent in
                            AgentParticipantRow(agent: agent)
                        }
                    }
                }
            }
            .navigationTitle("Nuovo Task Collaborativo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Crea") {
                        createTask()
                    }
                    .disabled(taskTitle.isEmpty)
                }
            }
        }
    }
    
    private func createTask() {
        let task = CollaborativeTask(
            id: UUID(),
            title: taskTitle,
            description: taskDescription,
            steps: selectedTemplate?.steps ?? [],
            expectedOutcome: selectedTemplate?.expectedOutcome ?? "Task completato",
            priority: .medium
        )
        
        onTaskCreated(task)
        dismiss()
    }
}
```

### **Fase 5: Template e Casi d'Uso (Settimana 8)**

#### 5.1 Template Predefiniti
```swift
// Models/TaskTemplate.swift
struct TaskTemplate: Identifiable {
    let id: UUID
    let title: String
    let description: String
    let category: Category
    let steps: [TaskStep]
    let requiredAgents: [AgentConfiguration]
    let expectedOutcome: String
    let estimatedDuration: TimeInterval
    
    enum Category: String, CaseIterable {
        case contentCreation = "Creazione Contenuti"
        case research = "Ricerca"
        case analysis = "Analisi"
        case automation = "Automazione"
        case brainstorming = "Brainstorming"
    }
    
    static let predefined: [TaskTemplate] = [
        // Template LinkedIn Post
        TaskTemplate(
            id: UUID(),
            title: "Crea Post LinkedIn",
            description: "Ricerca trend, scrivi e pubblica un post LinkedIn coinvolgente",
            category: .contentCreation,
            steps: [
                TaskStep(
                    id: UUID(),
                    description: "Ricerca trend attuali nel settore",
                    requiredCapabilities: [.webSearch],
                    dependsOn: nil,
                    estimatedDuration: 120
                ),
                TaskStep(
                    id: UUID(),
                    description: "Scrivi il contenuto del post",
                    requiredCapabilities: [.contentGeneration],
                    dependsOn: nil,
                    estimatedDuration: 180
                ),
                TaskStep(
                    id: UUID(),
                    description: "Pubblica su LinkedIn",
                    requiredCapabilities: [.socialMediaPosting],
                    dependsOn: nil,
                    estimatedDuration: 30
                )
            ],
            requiredAgents: [
                .trendResearcher,
                .contentWriter,
                .socialMediaPublisher
            ],
            expectedOutcome: "Post LinkedIn pubblicato con successo",
            estimatedDuration: 330
        ),
        
        // Template Analisi Competitiva
        TaskTemplate(
            id: UUID(),
            title: "Analisi Competitiva",
            description: "Analizza i competitor e genera report dettagliato",
            category: .analysis,
            steps: [
                TaskStep(
                    id: UUID(),
                    description: "Identifica competitor principali",
                    requiredCapabilities: [.webSearch],
                    dependsOn: nil,
                    estimatedDuration: 180
                ),
                TaskStep(
                    id: UUID(),
                    description: "Analizza strategie e positioning",
                    requiredCapabilities: [.dataAnalysis],
                    dependsOn: nil,
                    estimatedDuration: 300
                ),
                TaskStep(
                    id: UUID(),
                    description: "Genera report finale",
                    requiredCapabilities: [.contentGeneration],
                    dependsOn: nil,
                    estimatedDuration: 240
                )
            ],
            requiredAgents: [
                .trendResearcher,
                AgentConfiguration.dataAnalyst,
                .contentWriter
            ],
            expectedOutcome: "Report di analisi competitiva completo",
            estimatedDuration: 720
        )
    ]
}
```

---

## 🚀 Piano di Migrazione

### Settimana 1-2: Foundation
1. ✅ Refactor servizi esistenti con BaseAgentService
2. ✅ Implementare AgentConfiguration unificato
3. ✅ Creare AgentConfigurationManager
4. ✅ Aggiornare UI per configurazione agenti

### Settimana 3-4: Multi-Agent Core
1. 🔄 Implementare AgentOrchestrator
2. 🔄 Creare ConversationEngine
3. 🔄 Sviluppare GroupConversation model
4. 🔄 Testing collaborazione base

### Settimana 5-6: N8N Integration
1. ⏳ Setup N8N workflows
2. ⏳ Implementare N8NIntegrationService
3. ⏳ Creare agenti automazione
4. ⏳ Testing end-to-end LinkedIn workflow

### Settimana 7-8: UI & Polish
1. ⏳ Implementare GroupChatView
2. ⏳ Creare TaskCreatorView
3. ⏳ Aggiungere template predefiniti
4. ⏳ Testing completo e ottimizzazioni

---

## 🎯 Risultato Finale

**Scenario d'Uso Completo**:
1. **Utente**: "Voglio creare un post LinkedIn sui trend AI del 2024"
2. **Sistema**: Crea automaticamente un task collaborativo
3. **Trend Researcher**: Ricerca i trend AI più rilevanti del 2024
4. **Utente**: Sceglie il trend "AI Agents in Business"
5. **Trend Researcher**: Approfondisce la ricerca su questo tema specifico
6. **Content Writer**: Scrive un post LinkedIn coinvolgente e professionale
7. **Social Media Publisher**: Pubblica automaticamente su LinkedIn
8. **Sistema**: Notifica il completamento con link al post pubblicato

**Benefici**:
- ✅ **Collaborazione Intelligente**: Agenti specializzati lavorano insieme
- ✅ **Automazione Completa**: Dal concept alla pubblicazione
- ✅ **Configurabilità**: Ogni agente è personalizzabile
- ✅ **Scalabilità**: Facile aggiungere nuovi agenti e capabilities
- ✅ **User Experience**: Interfaccia intuitiva stile chat di gruppo
- ✅ **Estensibilità**: Architettura modulare per future espansioni

---

## 📝 Note Tecniche

### Backward Compatibility
- Tutte le chat esistenti continueranno a funzionare
- Migrazione graduale opzionale verso agenti configurabili
- Fallback automatico ai servizi legacy se necessario

### Performance Considerations
- Lazy loading dei messaggi nelle conversazioni lunghe
- Caching intelligente delle risposte degli agenti
- Ottimizzazione delle chiamate API con batching
- Background processing per task non urgenti

### Security & Privacy
- Encryption delle configurazioni agenti sensibili
- API key management sicuro
- Audit log delle azioni automatiche
- Controllo granulare dei permessi per automazioni

Questo piano unificato trasforma AgentChat in una piattaforma collaborativa di nuova generazione, mantenendo la semplicità d'uso ma aggiungendo potenti capacità di automazione e collaborazione multi-agente.