# Piano di Refactoring - AgentChat

## 🔍 Analisi dei Problemi Identificati

### 1. **Duplicazione Massiva di Codice nei Servizi**
**Gravità: ALTA** 🔴

**Problemi:**
- Tutti i servizi (OpenAI, Anthropic, Mistral, Grok, Perplexity) hanno codice quasi identico
- Gestione errori duplicata in ogni servizio
- Logica di validazione API key ripetuta
- Struttura HTTP request/response identica
- Parsing JSON duplicato

**Impatto:**
- Manutenzione difficile
- Bug propagati in tutti i servizi
- Violazione del principio DRY
- Codice verboso e difficile da testare

### 2. **Modelli di Dati Ridondanti**
**Gravità: MEDIA** 🟡

**Problemi:**
- Strutture Request/Response quasi identiche per ogni provider
- Duplicazione di campi comuni (model, messages, temperature, etc.)
- Mapping JSON ripetitivo
- Mancanza di astrazione comune

### 3. **Architettura Chat Confusa**
**Gravità: ALTA** 🔴

**Problemi:**
- Classe `Chat` con troppi inizializzatori
- Logica mista tra chat tradizionali e configurabili
- Proprietà opzionali che creano stati inconsistenti
- Responsabilità non chiare (Chat fa troppo)

### 4. **Gestione Stato Complessa**
**Gravità: MEDIA** 🟡

**Problemi:**
- `ChatDetailView` con troppi `@State` e `@StateObject`
- Logica di business nelle viste
- Accoppiamento forte tra UI e logica
- Difficile testing delle viste

### 5. **Enum AgentType Sovraccarico**
**Gravità: BASSA** 🟢

**Problemi:**
- Troppi casi nell'enum
- Logica di presentazione mescolata con logica di business
- Difficile estensibilità

### 6. **Mancanza di Dependency Injection**
**Gravità: MEDIA** 🟡

**Problemi:**
- Singleton pattern ovunque
- Difficile testing
- Accoppiamento forte
- Impossibile mock per test

## 🎯 Piano di Implementazione

### **Fase 1: Refactoring Servizi (Priorità ALTA)**

#### 1.1 Creare Base Service Astratta
```swift
// BaseHTTPService.swift
abstract class BaseHTTPService: ChatServiceProtocol {
    // Logica comune HTTP
    // Gestione errori unificata
    // Validazione API key generica
}
```

#### 1.2 Unificare Modelli di Dati
```swift
// CommonModels.swift
struct UnifiedRequest {
    let model: String
    let messages: [ChatMessage]
    let parameters: RequestParameters
}

struct RequestParameters {
    let temperature: Double?
    let maxTokens: Int?
    let topP: Double?
    // Altri parametri comuni
}
```

#### 1.3 Provider Configuration
```swift
// ProviderConfiguration.swift
struct ProviderConfiguration {
    let baseURL: String
    let authHeaderName: String
    let apiVersion: String?
    let requestTransformer: (UnifiedRequest) -> Data
    let responseParser: (Data) -> String
}
```

### **Fase 2: Semplificare Architettura Chat**

#### 2.1 Separare Tipi di Chat
```swift
// ChatTypes.swift
protocol ChatProtocol {
    var id: UUID { get }
    var title: String { get }
    var messages: [Message] { get }
}

class StandardChat: ChatProtocol { }
class ConfigurableChat: ChatProtocol { }
class GroupChat: ChatProtocol { }
```

#### 2.2 Chat Factory
```swift
// ChatFactory.swift
class ChatFactory {
    static func createChat(type: ChatCreationType) -> ChatProtocol {
        // Factory logic
    }
}
```

### **Fase 3: Dependency Injection**

#### 3.1 Service Container
```swift
// ServiceContainer.swift
class ServiceContainer {
    private var services: [String: Any] = [:]
    
    func register<T>(_ type: T.Type, factory: @escaping () -> T)
    func resolve<T>(_ type: T.Type) -> T?
}
```

#### 3.2 Refactor Viste
```swift
// ChatDetailViewModel.swift
class ChatDetailViewModel: ObservableObject {
    private let chatService: ChatServiceProtocol
    private let memoryManager: AgentMemoryManager
    
    init(chatService: ChatServiceProtocol, memoryManager: AgentMemoryManager) {
        self.chatService = chatService
        self.memoryManager = memoryManager
    }
}
```

### **Fase 4: Miglioramenti Architetturali**

#### 4.1 Repository Pattern per Persistenza
```swift
// ChatRepository.swift
protocol ChatRepository {
    func save(_ chat: ChatProtocol) async throws
    func load(id: UUID) async throws -> ChatProtocol?
    func loadAll() async throws -> [ChatProtocol]
}
```

#### 4.2 Event System
```swift
// EventBus.swift
class EventBus {
    func publish<T: Event>(_ event: T)
    func subscribe<T: Event>(_ type: T.Type, handler: @escaping (T) -> Void)
}
```

## 📋 Checklist Implementazione

### Fase 1: Servizi (Settimana 1-2)
- [ ] Creare `BaseHTTPService`
- [ ] Unificare modelli request/response
- [ ] Creare `ProviderConfiguration`
- [ ] Refactor tutti i servizi esistenti
- [ ] Aggiungere test unitari

### Fase 2: Chat Architecture (Settimana 3)
- [ ] Definire protocolli chat
- [ ] Implementare chat types specifici
- [ ] Creare ChatFactory
- [ ] Migrare dati esistenti

### Fase 3: Dependency Injection (Settimana 4)
- [ ] Implementare ServiceContainer
- [ ] Creare ViewModels
- [ ] Refactor viste principali
- [ ] Aggiornare test

### Fase 4: Miglioramenti (Settimana 5-6)
- [ ] Implementare Repository pattern
- [ ] Aggiungere Event system
- [ ] Ottimizzare performance
- [ ] Documentazione completa

## 🎯 Benefici Attesi

### Immediati
- ✅ **-70% linee di codice** nei servizi
- ✅ **Eliminazione duplicazioni** complete
- ✅ **Manutenibilità** drasticamente migliorata
- ✅ **Bug fixing** centralizzato

### A Medio Termine
- ✅ **Testing** semplificato e completo
- ✅ **Nuovi provider** aggiunti in minuti
- ✅ **Performance** ottimizzate
- ✅ **Scalabilità** migliorata

### A Lungo Termine
- ✅ **Architettura** pulita e mantenibile
- ✅ **Team development** facilitato
- ✅ **Feature development** accelerato
- ✅ **Code quality** enterprise-level

## ⚠️ Rischi e Mitigazioni

### Rischi
1. **Breaking changes** durante refactoring
2. **Regressioni** funzionali
3. **Complessità temporanea** durante transizione

### Mitigazioni
1. **Test coverage** al 100% prima del refactoring
2. **Feature flags** per rollback rapido
3. **Refactoring incrementale** con validazione continua
4. **Backup completo** prima di ogni fase

## 🚀 Prossimi Passi

1. **Approvazione piano** e priorità
2. **Setup ambiente test** completo
3. **Inizio Fase 1** con BaseHTTPService
4. **Monitoraggio progress** settimanale
5. **Review intermedi** dopo ogni fase

---

**Tempo stimato totale: 6 settimane**
**Effort: ~120 ore sviluppo + 40 ore testing**
**ROI: Manutenibilità +300%, Velocità sviluppo +200%**