# Piano Implementazione Sistema Multi-Agente Ibrido per AgentChat iOS

## 📋 Analisi Architettura Esistente

### Punti di Forza Attuali
- ✅ **Pattern MVVM** ben implementato con SwiftUI
- ✅ **ChatServiceProtocol** unificato per tutti i provider
- ✅ **ChatServiceFactory** per gestione servizi
- ✅ **Chat Model** reattivo con `@ObservableObject`
- ✅ **AgentType enum** estensibile
- ✅ **UI modulare** con Views separate

### Integrazione Strategica
Il sistema multi-agente si integrerà perfettamente nell'architettura esistente:
- Nuovi `AgentType` per gruppi multi-agente
- Estensione del `ChatServiceProtocol` per conversazioni di gruppo
- Nuove Views per UI gruppi stile WhatsApp
- Mantenimento compatibilità con chat singole esistenti

---

## 🚀 Roadmap Implementazione (6 Settimane)

### Fase 1: Core Multi-Agente (Settimana 1-2)

#### 1.1 Estensione AgentType
```swift
enum AgentType: String, CaseIterable, Identifiable {
    // Esistenti
    case openAI = "OpenAI"
    case claude = "Claude"
    case mistral = "Mistral"
    case perplexity = "Perplexity"
    case grok = "Grok"
    case n8n = "n8n"
    case custom = "Custom"
    
    // Nuovi Multi-Agente
    case hybridMultiAgent = "Hybrid Multi-Agent"
    case agentGroup = "Agent Group"
    case productTeam = "Product Team"
    case brainstormingSquad = "Brainstorming Squad"
    case codeReviewPanel = "Code Review Panel"
    
    var id: String { rawValue }
    
    var isMultiAgent: Bool {
        switch self {
        case .hybridMultiAgent, .agentGroup, .productTeam, .brainstormingSquad, .codeReviewPanel:
            return true
        default:
            return false
        }
    }
}
```

#### 1.2 HybridMultiAgentService
**File**: `Services/HybridMultiAgentService.swift`

```swift
import Foundation
import Combine

class HybridMultiAgentService: ChatServiceProtocol {
    static let shared = HybridMultiAgentService()
    
    private let coreAgents = CoreAgentSystem()
    private let remoteService = RemoteAgentService()
    private let responseCache = ResponseCache()
    
    var supportedModels: [String] {
        ["hybrid-fast", "hybrid-balanced", "hybrid-deep"]
    }
    
    var providerName: String { "Hybrid Multi-Agent" }
    
    func sendMessage(_ message: String, model: String?) async throws -> String {
        let complexity = analyzeComplexity(message)
        
        if let cached = responseCache.get(message) {
            return cached
        }
        
        let response: String
        if complexity.isSimple {
            response = try await coreAgents.processLocally(message)
        } else {
            response = try await remoteService.processRemotely(message, complexity: complexity)
        }
        
        responseCache.set(message, response: response)
        return response
    }
    
    func validateConfiguration() async throws -> Bool {
        return true // Sempre disponibile
    }
    
    private func analyzeComplexity(_ message: String) -> MessageComplexity {
        // Analisi euristica della complessità
        let wordCount = message.split(separator: " ").count
        let hasCodeKeywords = message.lowercased().contains("code") || 
                             message.lowercased().contains("function") ||
                             message.lowercased().contains("algorithm")
        
        if wordCount < 10 && !hasCodeKeywords {
            return .simple
        } else if wordCount < 50 {
            return .medium
        } else {
            return .complex
        }
    }
}

enum MessageComplexity {
    case simple, medium, complex
    
    var isSimple: Bool {
        return self == .simple
    }
}
```

#### 1.3 CoreAgentSystem
**File**: `Services/CoreAgentSystem.swift`

```swift
import Foundation

class CoreAgentSystem {
    private let quickResponse = QuickResponseAgent()
    private let basicConversation = BasicConversationAgent()
    private let simpleAnalysis = SimpleAnalysisAgent()
    
    func processLocally(_ message: String) async throws -> String {
        // Routing locale basato su pattern
        if isQuickResponse(message) {
            return try await quickResponse.process(message)
        } else if isAnalysisRequest(message) {
            return try await simpleAnalysis.process(message)
        } else {
            return try await basicConversation.process(message)
        }
    }
    
    private func isQuickResponse(_ message: String) -> Bool {
        let quickPatterns = ["ciao", "hello", "grazie", "thanks", "ok", "sì", "no"]
        return quickPatterns.contains { message.lowercased().contains($0) }
    }
    
    private func isAnalysisRequest(_ message: String) -> Bool {
        let analysisPatterns = ["analizza", "analyze", "confronta", "compare", "riassumi", "summarize"]
        return analysisPatterns.contains { message.lowercased().contains($0) }
    }
}

// Agenti Core Locali
class QuickResponseAgent {
    func process(_ message: String) async throws -> String {
        // Risposte immediate predefinite
        let responses = [
            "ciao": "Ciao! Come posso aiutarti oggi?",
            "hello": "Hello! How can I help you?",
            "grazie": "Prego! È stato un piacere aiutarti.",
            "thanks": "You're welcome! Happy to help."
        ]
        
        for (pattern, response) in responses {
            if message.lowercased().contains(pattern) {
                return response
            }
        }
        
        return "Come posso aiutarti?"
    }
}

class BasicConversationAgent {
    func process(_ message: String) async throws -> String {
        // Conversazione base con template
        return "Ho ricevuto il tuo messaggio: '\(message)'. Sto elaborando una risposta appropriata..."
    }
}

class SimpleAnalysisAgent {
    func process(_ message: String) async throws -> String {
        let wordCount = message.split(separator: " ").count
        let charCount = message.count
        
        return """
        📊 Analisi rapida del messaggio:
        • Parole: \(wordCount)
        • Caratteri: \(charCount)
        • Tipo: \(wordCount > 20 ? "Messaggio lungo" : "Messaggio breve")
        """
    }
}
```

### Fase 2: Sistema Gruppi Agenti (Settimana 2-3)

#### 2.1 Modelli Gruppo
**File**: `Models/AgentGroup.swift`

```swift
import Foundation
import Combine

class AgentGroup: ObservableObject, Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let icon: String
    
    @Published var participants: [GroupAgent]
    @Published var messages: [GroupMessage] = []
    @Published var isActive: Bool = false
    @Published var currentSpeaker: GroupAgent?
    
    private let conversationEngine = GroupConversationEngine()
    
    init(name: String, description: String, icon: String, participants: [GroupAgent]) {
        self.name = name
        self.description = description
        self.icon = icon
        self.participants = participants
    }
    
    func startGroupConversation(with prompt: String) async {
        isActive = true
        
        // Messaggio iniziale dell'utente
        let userMessage = GroupMessage(
            content: prompt,
            sender: .user,
            timestamp: Date()
        )
        
        await MainActor.run {
            messages.append(userMessage)
        }
        
        // Avvia conversazione orchestrata
        await conversationEngine.orchestrateGroupDiscussion(
            initialPrompt: prompt,
            participants: participants,
            messageHandler: { [weak self] message in
                await self?.addMessage(message)
            }
        )
        
        isActive = false
    }
    
    @MainActor
    private func addMessage(_ message: GroupMessage) {
        messages.append(message)
        if case .agent(let agent) = message.sender {
            currentSpeaker = agent
        }
    }
}

struct GroupMessage: Identifiable {
    let id = UUID()
    let content: String
    let sender: MessageSender
    let timestamp: Date
    
    enum MessageSender {
        case user
        case agent(GroupAgent)
        
        var displayName: String {
            switch self {
            case .user:
                return "Tu"
            case .agent(let agent):
                return agent.name
            }
        }
        
        var isUser: Bool {
            if case .user = self { return true }
            return false
        }
    }
}
```

#### 2.2 GroupAgent
**File**: `Models/GroupAgent.swift`

```swift
import Foundation

struct GroupAgent: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let role: String
    let personality: String
    let icon: String
    let systemPrompt: String
    let preferredService: ChatServiceProtocol
    
    static let dataAnalyst = GroupAgent(
        name: "Data Analyst",
        role: "Analista Dati",
        personality: "Metodico, orientato ai dati, preciso nelle analisi",
        icon: "📊",
        systemPrompt: "Sei un analista dati esperto. Fornisci sempre analisi basate su dati concreti e statistiche. Sii preciso e metodico.",
        preferredService: OpenAIService.shared
    )
    
    static let creativeDirector = GroupAgent(
        name: "Creative Director",
        role: "Direttore Creativo",
        personality: "Visionaria, creativa, pensa fuori dagli schemi",
        icon: "🎨",
        systemPrompt: "Sei un direttore creativo innovativo. Proponi sempre soluzioni creative e originali. Pensa fuori dagli schemi.",
        preferredService: AnthropicService.shared
    )
    
    static let techLead = GroupAgent(
        name: "Tech Lead",
        role: "Lead Tecnico",
        personality: "Pragmatico, focalizzato su soluzioni tecniche efficienti",
        icon: "⚙️",
        systemPrompt: "Sei un tech lead esperto. Fornisci sempre soluzioni tecniche pragmatiche e fattibili. Considera performance e scalabilità.",
        preferredService: OpenAIService.shared
    )
    
    static let strategist = GroupAgent(
        name: "Strategist",
        role: "Strategist",
        personality: "Business-oriented, visione a lungo termine",
        icon: "🎯",
        systemPrompt: "Sei uno strategist business. Pensa sempre al lungo termine e all'impatto sul business. Considera ROI e sostenibilità.",
        preferredService: PerplexityService.shared
    )
    
    static let critic = GroupAgent(
        name: "Critic",
        role: "Critico Costruttivo",
        personality: "Scettico costruttivo, trova problemi e limitazioni",
        icon: "🔍",
        systemPrompt: "Sei un critico costruttivo. Il tuo ruolo è trovare potenziali problemi e limitazioni nelle proposte. Sii scettico ma costruttivo.",
        preferredService: AnthropicService.shared
    )
    
    func generateResponse(to message: String, context: [GroupMessage]) async throws -> String {
        let contextString = context.suffix(3).map { "\($0.sender.displayName): \($0.content)" }.joined(separator: "\n")
        
        let fullPrompt = """
        \(systemPrompt)
        
        Contesto conversazione:
        \(contextString)
        
        Rispondi come \(name) (\(role)) al seguente messaggio:
        \(message)
        
        Mantieni il tuo stile: \(personality)
        """
        
        return try await preferredService.sendMessage(fullPrompt, model: nil)
    }
}
```

### Fase 3: Engine Conversazione (Settimana 3-4)

#### 3.1 GroupConversationEngine
**File**: `Services/GroupConversationEngine.swift`

```swift
import Foundation

class GroupConversationEngine {
    private let maxRounds = 8
    private let pauseBetweenMessages: UInt64 = 2_000_000_000 // 2 secondi
    
    func orchestrateGroupDiscussion(
        initialPrompt: String,
        participants: [GroupAgent],
        messageHandler: @escaping (GroupMessage) async -> Void
    ) async {
        var conversationHistory: [GroupMessage] = []
        var currentRound = 0
        
        while currentRound < maxRounds {
            let nextAgent = selectNextAgent(participants, round: currentRound, history: conversationHistory)
            
            do {
                let response = try await nextAgent.generateResponse(
                    to: initialPrompt,
                    context: conversationHistory
                )
                
                let message = GroupMessage(
                    content: response,
                    sender: .agent(nextAgent),
                    timestamp: Date()
                )
                
                conversationHistory.append(message)
                await messageHandler(message)
                
                // Pausa realistica tra messaggi
                try await Task.sleep(nanoseconds: pauseBetweenMessages)
                
                if shouldEndConversation(response, round: currentRound) {
                    break
                }
                
            } catch {
                print("Errore nella generazione risposta per \(nextAgent.name): \(error)")
            }
            
            currentRound += 1
        }
        
        // Messaggio di chiusura
        let closingMessage = GroupMessage(
            content: "🎯 Discussione completata! Abbiamo esplorato diverse prospettive su questo argomento.",
            sender: .agent(participants.first!),
            timestamp: Date()
        )
        await messageHandler(closingMessage)
    }
    
    private func selectNextAgent(
        _ participants: [GroupAgent],
        round: Int,
        history: [GroupMessage]
    ) -> GroupAgent {
        // Strategia di selezione intelligente
        if round == 0 {
            // Primo round: inizia con lo strategist
            return participants.first { $0.name == "Strategist" } ?? participants[0]
        }
        
        // Evita ripetizioni consecutive
        let lastSpeaker = history.last?.sender
        let availableAgents = participants.filter { agent in
            if case .agent(let lastAgent) = lastSpeaker {
                return agent.id != lastAgent.id
            }
            return true
        }
        
        // Rotazione intelligente basata sul contenuto
        let lastMessage = history.last?.content.lowercased() ?? ""
        
        if lastMessage.contains("dati") || lastMessage.contains("analisi") {
            return availableAgents.first { $0.name == "Data Analyst" } ?? availableAgents.randomElement()!
        } else if lastMessage.contains("creativo") || lastMessage.contains("innovativo") {
            return availableAgents.first { $0.name == "Creative Director" } ?? availableAgents.randomElement()!
        } else if lastMessage.contains("tecnico") || lastMessage.contains("implementazione") {
            return availableAgents.first { $0.name == "Tech Lead" } ?? availableAgents.randomElement()!
        } else if lastMessage.contains("problema") || lastMessage.contains("rischio") {
            return availableAgents.first { $0.name == "Critic" } ?? availableAgents.randomElement()!
        }
        
        // Default: rotazione sequenziale
        return availableAgents[round % availableAgents.count]
    }
    
    private func shouldEndConversation(_ response: String, round: Int) -> Bool {
        let endKeywords = ["conclusione", "riassumendo", "in sintesi", "per concludere"]
        let hasEndKeyword = endKeywords.contains { response.lowercased().contains($0) }
        
        return hasEndKeyword || round >= maxRounds - 1
    }
}
```

### Fase 4: Integrazione ChatService (Settimana 4)

#### 4.1 Aggiornamento ChatServiceFactory
**File**: `Services/ChatService.swift` (aggiornamento)

```swift
// Aggiungere al ChatServiceFactory esistente
extension ChatServiceFactory {
    static func createService(for agentType: AgentType) -> ChatServiceProtocol? {
        switch agentType {
        case .openAI:
            return OpenAIService.shared
        case .claude:
            return AnthropicService.shared
        case .mistral:
            return MistralService.shared
        case .perplexity:
            return PerplexityService.shared
        case .grok:
            return GrokService.shared
        case .n8n:
            return N8NService.shared
        case .custom:
            return CustomProviderService.shared
        // Nuovi servizi multi-agente
        case .hybridMultiAgent:
            return HybridMultiAgentService.shared
        case .agentGroup, .productTeam, .brainstormingSquad, .codeReviewPanel:
            return GroupChatService.shared
        }
    }
}
```

#### 4.2 GroupChatService
**File**: `Services/GroupChatService.swift`

```swift
import Foundation

class GroupChatService: ChatServiceProtocol {
    static let shared = GroupChatService()
    
    var supportedModels: [String] {
        ["product-team", "brainstorming-squad", "code-review-panel", "custom-group"]
    }
    
    var providerName: String { "Agent Group" }
    
    func sendMessage(_ message: String, model: String?) async throws -> String {
        // Questo servizio gestisce solo l'inizializzazione
        // La conversazione vera avviene tramite AgentGroup
        return "Gruppo agenti inizializzato. La conversazione inizierà a breve..."
    }
    
    func validateConfiguration() async throws -> Bool {
        return true
    }
}
```

### Fase 5: UI Gruppi WhatsApp-Style (Settimana 5-6)

#### 5.1 GroupChatView
**File**: `Views/GroupChatView.swift`

```swift
import SwiftUI

struct GroupChatView: View {
    @ObservedObject var group: AgentGroup
    @State private var inputText = ""
    @FocusState private var isInputFocused: Bool
    @State private var isConversationActive = false
    
    var body: some View {
        VStack(spacing: 0) {
            GroupHeaderView(group: group)
            
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(group.messages) { message in
                            GroupMessageBubble(message: message)
                                .id(message.id)
                        }
                        
                        if group.isActive {
                            TypingIndicatorView(currentSpeaker: group.currentSpeaker)
                        }
                    }
                    .padding(.horizontal)
                }
                .onChange(of: group.messages) { _, newMessages in
                    if let lastMessage = newMessages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            Divider()
            
            GroupInputView(
                inputText: $inputText,
                isInputFocused: $isInputFocused,
                isActive: group.isActive,
                onSend: { message in
                    Task {
                        await group.startGroupConversation(with: message)
                    }
                }
            )
        }
        .navigationTitle(group.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct GroupHeaderView: View {
    let group: AgentGroup
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(group.icon)
                    .font(.title2)
                Text(group.name)
                    .font(.headline)
                Spacer()
                Text("\(group.participants.count) agenti")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(group.participants) { agent in
                        AgentAvatarView(agent: agent, isActive: group.currentSpeaker?.id == agent.id)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
    }
}

struct AgentAvatarView: View {
    let agent: GroupAgent
    let isActive: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            Text(agent.icon)
                .font(.title3)
                .frame(width: 40, height: 40)
                .background(isActive ? Color.accentColor.opacity(0.3) : Color.gray.opacity(0.2))
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(isActive ? Color.accentColor : Color.clear, lineWidth: 2)
                )
            
            Text(agent.name.split(separator: " ").first ?? "")
                .font(.caption2)
                .foregroundColor(isActive ? .accentColor : .secondary)
        }
    }
}

struct GroupMessageBubble: View {
    let message: GroupMessage
    
    var body: some View {
        HStack {
            if message.sender.isUser {
                Spacer()
                userMessageBubble
            } else {
                agentMessageBubble
                Spacer()
            }
        }
    }
    
    private var userMessageBubble: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(message.content)
                .padding(12)
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(16)
            
            Text("Tu • \(formatTime(message.timestamp))")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity * 0.8, alignment: .trailing)
    }
    
    private var agentMessageBubble: some View {
        VStack(alignment: .leading, spacing: 4) {
            if case .agent(let agent) = message.sender {
                HStack(spacing: 8) {
                    Text(agent.icon)
                        .font(.caption)
                    Text(agent.name)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.accentColor)
                    Spacer()
                }
            }
            
            Text(message.content)
                .padding(12)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(16)
            
            Text(formatTime(message.timestamp))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity * 0.8, alignment: .leading)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct GroupInputView: View {
    @Binding var inputText: String
    var isInputFocused: FocusState<Bool>.Binding
    let isActive: Bool
    let onSend: (String) -> Void
    
    var body: some View {
        HStack {
            TextField("Avvia discussione di gruppo...", text: $inputText, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .focused(isInputFocused)
                .lineLimit(1...5)
                .disabled(isActive)
            
            Button {
                let message = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
                if !message.isEmpty {
                    onSend(message)
                    inputText = ""
                }
            } label: {
                if isActive {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "paperplane.fill")
                }
            }
            .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isActive)
        }
        .padding()
        .background(.ultraThinMaterial)
    }
}

struct TypingIndicatorView: View {
    let currentSpeaker: GroupAgent?
    @State private var animationPhase = 0
    
    var body: some View {
        if let speaker = currentSpeaker {
            HStack {
                Text(speaker.icon)
                    .font(.caption)
                Text("\(speaker.name) sta scrivendo")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 2) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(Color.secondary)
                            .frame(width: 4, height: 4)
                            .opacity(animationPhase == index ? 1 : 0.3)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.6).repeatForever()) {
                    animationPhase = (animationPhase + 1) % 3
                }
            }
        }
    }
}
```

### Fase 6: Integrazione e Template (Settimana 6)

#### 6.1 Aggiornamento NewChatView
**File**: `Views/NewChatView.swift` (aggiornamento)

```swift
// Aggiungere sezione per gruppi agenti
Section {
    ForEach(AgentGroupTemplate.allTemplates) { template in
        GroupTemplateRow(
            template: template,
            isSelected: selectedGroupTemplate?.id == template.id
        ) {
            selectedGroupTemplate = template
            selectedProvider = nil
            selectedWorkflow = nil
        }
    }
} header: {
    Text("Gruppi Agenti")
} footer: {
    Text("Gruppi di agenti specializzati che collaborano per risolvere problemi complessi")
}
```

#### 6.2 Template Gruppi
**File**: `Models/AgentGroupTemplate.swift`

```swift
import Foundation

struct AgentGroupTemplate: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let icon: String
    let participants: [GroupAgent]
    let agentType: AgentType
    
    static let productTeam = AgentGroupTemplate(
        name: "Product Development Team",
        description: "Team completo per sviluppo prodotto: strategia, design, tech e analisi",
        icon: "🚀",
        participants: [
            .strategist,
            .techLead,
            .creativeDirector,
            .dataAnalyst,
            .critic
        ],
        agentType: .productTeam
    )
    
    static let brainstormingSquad = AgentGroupTemplate(
        name: "Brainstorming Squad",
        description: "Gruppo creativo per generazione idee innovative",
        icon: "💡",
        participants: [
            .creativeDirector,
            .strategist,
            .critic
        ],
        agentType: .brainstormingSquad
    )
    
    static let codeReviewPanel = AgentGroupTemplate(
        name: "Code Review Panel",
        description: "Panel di esperti per revisione codice e architettura",
        icon: "🔍",
        participants: [
            .techLead,
            .critic,
            .dataAnalyst
        ],
        agentType: .codeReviewPanel
    )
    
    static let allTemplates: [AgentGroupTemplate] = [
        .productTeam,
        .brainstormingSquad,
        .codeReviewPanel
    ]
    
    func createGroup() -> AgentGroup {
        return AgentGroup(
            name: name,
            description: description,
            icon: icon,
            participants: participants
        )
    }
}
```

---

## 🎯 Risultati Attesi

### Funzionalità Implementate
- ✅ **Sistema ibrido** locale + remoto
- ✅ **Gruppi agenti** con personalità distinte
- ✅ **UI WhatsApp-style** per conversazioni di gruppo
- ✅ **Template predefiniti** per casi d'uso comuni
- ✅ **Integrazione seamless** con architettura esistente

### Benefici
- 🚀 **Performance**: Risposte immediate per query semplici
- 🧠 **Intelligenza**: Conversazioni multi-prospettiva
- 🎨 **UX**: Interfaccia familiare e intuitiva
- 🔧 **Estensibilità**: Facile aggiunta nuovi agenti e gruppi
- 📱 **Compatibilità**: Mantiene tutte le funzionalità esistenti

---

## 📋 Checklist Implementazione

### Settimana 1-2: Core
- [ ] Estendere `AgentType` enum
- [ ] Implementare `HybridMultiAgentService`
- [ ] Creare `CoreAgentSystem`
- [ ] Aggiornare `ChatServiceFactory`

### Settimana 2-3: Gruppi
- [ ] Implementare `AgentGroup` model
- [ ] Creare `GroupAgent` con personalità
- [ ] Sviluppare `GroupConversationEngine`
- [ ] Testare orchestrazione conversazioni

### Settimana 3-4: Engine
- [ ] Ottimizzare algoritmi selezione agenti
- [ ] Implementare cache risposte
- [ ] Aggiungere gestione errori robusta
- [ ] Creare `GroupChatService`

### Settimana 4-5: UI Base
- [ ] Implementare `GroupChatView`
- [ ] Creare componenti UI specializzati
- [ ] Aggiungere animazioni e transizioni
- [ ] Testare UX su dispositivi

### Settimana 5-6: Integrazione
- [ ] Aggiornare `NewChatView`
- [ ] Creare template gruppi
- [ ] Integrare con `ChatManager`
- [ ] Testing completo e debugging

### Settimana 6: Finalizzazione
- [ ] Ottimizzazioni performance
- [ ] Documentazione codice
- [ ] Testing su casi edge
- [ ] Preparazione release

---

**Questo piano mantiene la compatibilità totale con l'architettura esistente mentre aggiunge potenti funzionalità multi-agente che trasformeranno l'esperienza utente di AgentChat.**