# Piano Implementazione Aggiornato - AgentChat con Agenti Configurabili

## 🎯 Obiettivi Principali

1. **Agenti Configurabili**: System prompt personalizzabili per ogni agente
2. **Memoria Persistente**: Gli agenti mantengono il contesto tra le sessioni
3. **Chat Singole Funzionanti**: Ripristino completo delle chat individuali
4. **Interfaccia Unificata**: Gestione seamless tra chat singole e di gruppo

---

## 📋 Fase 1: Ripristino Chat Singole (Settimana 1)

### 1.1 Verifica e Fix ChatService Esistenti

**Obiettivo**: Assicurarsi che tutti i servizi di chat singola funzionino correttamente

**File da verificare/aggiornare**:
- `Services/OpenAIService.swift`
- `Services/AnthropicService.swift`
- `Services/MistralService.swift`
- `Services/PerplexityService.swift`
- `Services/GrokService.swift`
- `Services/CustomProviderService.swift`

**Azioni**:
1. Test di tutti i servizi esistenti
2. Fix eventuali problemi di configurazione API
3. Verifica compatibilità con l'UI attuale
4. Aggiornamento gestione errori

### 1.2 Aggiornamento ChatDetailView

**File**: `Views/ChatDetailView.swift`

```swift
// Assicurarsi che supporti sia chat singole che di gruppo
struct ChatDetailView: View {
    @ObservedObject var chat: Chat
    @State private var messageText = ""
    @State private var isLoading = false
    
    var body: some View {
        VStack {
            // Lista messaggi con supporto per agenti multipli
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(chat.messages) { message in
                        MessageBubbleView(message: message)
                    }
                }
            }
            
            // Input area
            MessageInputView(
                text: $messageText,
                isLoading: $isLoading,
                onSend: sendMessage
            )
        }
        .navigationTitle(chat.title)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if chat.isGroupChat {
                    GroupChatSettingsButton(chat: chat)
                } else {
                    SingleChatSettingsButton(chat: chat)
                }
            }
        }
    }
    
    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        Task {
            await chat.sendMessage(messageText)
            messageText = ""
        }
    }
}
```

---

## 📋 Fase 2: Sistema Agenti Configurabili (Settimana 2)

### 2.1 Modello AgentConfiguration

**File**: `Models/AgentConfiguration.swift`

```swift
import Foundation
import SwiftUI

struct AgentConfiguration: Identifiable, Codable {
    let id = UUID()
    var name: String
    var systemPrompt: String
    var personality: String
    var role: String
    var icon: String
    var preferredProvider: String
    var temperature: Double
    var maxTokens: Int
    var isActive: Bool
    var memoryEnabled: Bool
    var contextWindow: Int // Numero di messaggi da ricordare
    
    static let defaultAgents: [AgentConfiguration] = [
        AgentConfiguration(
            name: "Assistente Generale",
            systemPrompt: "Sei un assistente AI utile e cordiale. Rispondi sempre in modo chiaro e preciso.",
            personality: "Cordiale, professionale, preciso",
            role: "Assistente Generale",
            icon: "🤖",
            preferredProvider: "OpenAI",
            temperature: 0.7,
            maxTokens: 2000,
            isActive: true,
            memoryEnabled: true,
            contextWindow: 10
        ),
        AgentConfiguration(
            name: "Esperto di Codice",
            systemPrompt: "Sei un esperto programmatore. Fornisci sempre codice pulito, ben commentato e seguendo le best practices.",
            personality: "Tecnico, preciso, orientato alle soluzioni",
            role: "Sviluppatore Senior",
            icon: "👨‍💻",
            preferredProvider: "OpenAI",
            temperature: 0.3,
            maxTokens: 4000,
            isActive: true,
            memoryEnabled: true,
            contextWindow: 15
        ),
        AgentConfiguration(
            name: "Creativo",
            systemPrompt: "Sei un creativo innovativo. Pensa fuori dagli schemi e proponi sempre idee originali e creative.",
            personality: "Creativo, visionario, innovativo",
            role: "Direttore Creativo",
            icon: "🎨",
            preferredProvider: "Claude",
            temperature: 0.9,
            maxTokens: 3000,
            isActive: true,
            memoryEnabled: true,
            contextWindow: 8
        )
    ]
}
```

### 2.2 AgentConfigurationManager

**File**: `Services/AgentConfigurationManager.swift`

```swift
import Foundation
import Combine

class AgentConfigurationManager: ObservableObject {
    static let shared = AgentConfigurationManager()
    
    @Published var agents: [AgentConfiguration] = []
    
    private let userDefaults = UserDefaults.standard
    private let agentsKey = "configured_agents"
    
    init() {
        loadAgents()
    }
    
    func loadAgents() {
        if let data = userDefaults.data(forKey: agentsKey),
           let decodedAgents = try? JSONDecoder().decode([AgentConfiguration].self, from: data) {
            agents = decodedAgents
        } else {
            // Prima volta: carica agenti di default
            agents = AgentConfiguration.defaultAgents
            saveAgents()
        }
    }
    
    func saveAgents() {
        if let encoded = try? JSONEncoder().encode(agents) {
            userDefaults.set(encoded, forKey: agentsKey)
        }
    }
    
    func addAgent(_ agent: AgentConfiguration) {
        agents.append(agent)
        saveAgents()
    }
    
    func updateAgent(_ agent: AgentConfiguration) {
        if let index = agents.firstIndex(where: { $0.id == agent.id }) {
            agents[index] = agent
            saveAgents()
        }
    }
    
    func deleteAgent(_ agent: AgentConfiguration) {
        agents.removeAll { $0.id == agent.id }
        saveAgents()
    }
    
    func getActiveAgents() -> [AgentConfiguration] {
        return agents.filter { $0.isActive }
    }
}
```

### 2.3 Vista Configurazione Agenti

**File**: `Views/AgentConfigurationView.swift`

```swift
import SwiftUI

struct AgentConfigurationView: View {
    @StateObject private var configManager = AgentConfigurationManager.shared
    @State private var showingAddAgent = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(configManager.agents) { agent in
                    NavigationLink(destination: AgentEditView(agent: agent)) {
                        AgentRowView(agent: agent)
                    }
                }
                .onDelete(perform: deleteAgents)
            }
            .navigationTitle("Configurazione Agenti")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Aggiungi") {
                        showingAddAgent = true
                    }
                }
            }
            .sheet(isPresented: $showingAddAgent) {
                AgentEditView(agent: nil)
            }
        }
    }
    
    private func deleteAgents(offsets: IndexSet) {
        for index in offsets {
            configManager.deleteAgent(configManager.agents[index])
        }
    }
}

struct AgentRowView: View {
    let agent: AgentConfiguration
    
    var body: some View {
        HStack {
            Text(agent.icon)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(agent.name)
                    .font(.headline)
                Text(agent.role)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if agent.isActive {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            } else {
                Image(systemName: "circle")
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 4)
    }
}
```

---

## 📋 Fase 3: Sistema Memoria Persistente (Settimana 3)

### 3.1 AgentMemoryManager

**File**: `Services/AgentMemoryManager.swift`

```swift
import Foundation
import CoreData

class AgentMemoryManager {
    static let shared = AgentMemoryManager()
    
    private init() {}
    
    // Salva contesto conversazione per un agente
    func saveConversationContext(
        agentId: UUID,
        chatId: UUID,
        messages: [Message],
        summary: String? = nil
    ) {
        let context = ConversationContext(
            agentId: agentId,
            chatId: chatId,
            messages: messages.suffix(10).map { $0 }, // Ultimi 10 messaggi
            summary: summary,
            timestamp: Date()
        )
        
        saveContext(context)
    }
    
    // Recupera contesto per un agente in una chat specifica
    func getConversationContext(agentId: UUID, chatId: UUID) -> ConversationContext? {
        return loadContext(agentId: agentId, chatId: chatId)
    }
    
    // Genera summary del contesto quando diventa troppo lungo
    func generateContextSummary(messages: [Message]) async -> String {
        let conversationText = messages.map { "\($0.isFromUser ? "User" : "Assistant"): \($0.content)" }
            .joined(separator: "\n")
        
        let summaryPrompt = """
        Riassumi questa conversazione in modo conciso, mantenendo i punti chiave e il contesto importante:
        
        \(conversationText)
        
        Riassunto:
        """
        
        // Usa un servizio per generare il summary
        do {
            return try await OpenAIService.shared.sendMessage(summaryPrompt, model: "gpt-3.5-turbo")
        } catch {
            return "Conversazione su vari argomenti"
        }
    }
    
    private func saveContext(_ context: ConversationContext) {
        // Implementazione salvataggio (UserDefaults o CoreData)
        let key = "context_\(context.agentId)_\(context.chatId)"
        if let encoded = try? JSONEncoder().encode(context) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }
    
    private func loadContext(agentId: UUID, chatId: UUID) -> ConversationContext? {
        let key = "context_\(agentId)_\(chatId)"
        guard let data = UserDefaults.standard.data(forKey: key),
              let context = try? JSONDecoder().decode(ConversationContext.self, from: data) else {
            return nil
        }
        return context
    }
}

struct ConversationContext: Codable {
    let agentId: UUID
    let chatId: UUID
    let messages: [Message]
    let summary: String?
    let timestamp: Date
}
```

---

## 🚀 Implementazione Immediata

### Priorità 1 (Questa settimana)
1. ✅ Ripristino chat singole funzionanti
2. ✅ Implementazione AgentConfiguration
3. ✅ Vista configurazione agenti base

### Priorità 2 (Prossima settimana)
1. Sistema memoria persistente
2. Integrazione memoria nelle chat esistenti
3. Aggiornamento interfaccia NewChatView

### Priorità 3 (Settimana successiva)
1. Chat di gruppo con agenti configurabili
2. Testing completo
3. Ottimizzazioni performance

---

## 📝 Note Implementative

- **Backward Compatibility**: Tutte le chat esistenti continueranno a funzionare
- **Gradual Migration**: Gli utenti potranno migrare gradualmente alle nuove funzionalità
- **Fallback Graceful**: Se un agente configurato non è disponibile, fallback ai servizi standard
- **Performance First**: Priorità alle performance, memoria solo quando necessaria