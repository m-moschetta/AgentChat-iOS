# Soluzioni Architetturali per AgentChat

## Problemi Identificati e Soluzioni

### 1. Gestione Memoria per Chat con Molti Messaggi

#### Problema Attuale
- Tutti i messaggi vengono caricati in memoria contemporaneamente
- Nessuna limitazione sul numero di messaggi visualizzati
- Potenziali memory leak con chat molto lunghe

#### Soluzioni Proposte

##### A. Paginazione Lazy Loading
```swift
class Chat: ObservableObject {
    @Published var messages: [Message] = []
    @Published var isLoadingMore = false
    private let pageSize = 50
    private var currentPage = 0
    
    func loadMoreMessages() async {
        guard !isLoadingMore else { return }
        isLoadingMore = true
        
        // Carica messaggi dal database con offset
        let newMessages = await ChatRepository.shared.loadMessages(
            chatId: id, 
            offset: currentPage * pageSize, 
            limit: pageSize
        )
        
        messages.insert(contentsOf: newMessages, at: 0)
        currentPage += 1
        isLoadingMore = false
    }
}
```

##### B. Message Virtualization
```swift
struct ChatDetailView: View {
    @ObservedObject var chat: Chat
    @State private var visibleRange: Range<Int> = 0..<50
    
    var body: some View {
        LazyVStack {
            ForEach(chat.messages[visibleRange], id: \.id) { message in
                MessageView(message: message)
                    .onAppear {
                        if message == chat.messages[visibleRange].last {
                            loadMoreIfNeeded()
                        }
                    }
            }
        }
    }
}
```

### 2. Mancanza di Paginazione Messaggi

#### Implementazione con CoreData

##### Core Data Model
```swift
// ChatEntity.xcdatamodeld
entity Chat {
    id: UUID
    agentType: String
    assistantId: String?
    createdAt: Date
    lastMessageAt: Date
    // Relationship
    messages: [MessageEntity]
}

entity MessageEntity {
    id: UUID
    text: String
    isUser: Bool
    timestamp: Date
    // Relationship
    chat: ChatEntity
}
```

##### Repository Pattern
```swift
protocol ChatRepositoryProtocol {
    func loadMessages(chatId: UUID, offset: Int, limit: Int) async -> [Message]
    func saveMessage(_ message: Message, toChatId chatId: UUID) async
    func loadChats(limit: Int, offset: Int) async -> [Chat]
}

class CoreDataChatRepository: ChatRepositoryProtocol {
    private let context: NSManagedObjectContext
    
    func loadMessages(chatId: UUID, offset: Int, limit: Int) async -> [Message] {
        let request: NSFetchRequest<MessageEntity> = MessageEntity.fetchRequest()
        request.predicate = NSPredicate(format: "chat.id == %@", chatId as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \MessageEntity.timestamp, ascending: false)]
        request.fetchOffset = offset
        request.fetchLimit = limit
        
        do {
            let entities = try context.fetch(request)
            return entities.map { $0.toMessage() }
        } catch {
            print("Error loading messages: \(error)")
            return []
        }
    }
}
```

### 3. Thread Management Solo in Memoria

#### Problema Attuale
```swift
private var threadIds: [UUID: String] = [:] // Perso al restart
```

#### Soluzione con Persistent Storage

##### A. CoreData + Keychain per Sicurezza
```swift
class PersistentThreadManager {
    private let repository: ChatRepositoryProtocol
    private let keychain: KeychainService
    
    func getOrCreateThread(for chatId: UUID) async throws -> String {
        // 1. Cerca thread esistente in CoreData
        if let existingThread = await repository.getThreadId(for: chatId) {
            return existingThread
        }
        
        // 2. Crea nuovo thread via API
        let threadId = try await createNewThread()
        
        // 3. Salva in CoreData
        await repository.saveThreadId(threadId, for: chatId)
        
        return threadId
    }
}

class KeychainService {
    func store(apiKey: String) {
        let data = apiKey.data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "openai_api_key",
            kSecValueData as String: data
        ]
        SecItemAdd(query as CFDictionary, nil)
    }
}
```

## Architettura Migliorata con Supabase

### Setup Supabase per iOS

#### 1. Dipendenze
```swift
// Package.swift o Xcode Package Manager
.package(url: "https://github.com/supabase/supabase-swift", from: "2.0.0")
```

#### 2. Database Schema
```sql
-- Supabase SQL Schema
CREATE TABLE chats (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    agent_type TEXT NOT NULL,
    assistant_id TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_message_at TIMESTAMP WITH TIME ZONE,
    thread_id TEXT -- OpenAI thread ID
);

CREATE TABLE messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    chat_id UUID REFERENCES chats(id) ON DELETE CASCADE,
    text TEXT NOT NULL,
    is_user BOOLEAN NOT NULL,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indici per performance
CREATE INDEX idx_messages_chat_timestamp ON messages(chat_id, timestamp DESC);
CREATE INDEX idx_chats_last_message ON chats(last_message_at DESC);
```

#### 3. Supabase Service
```swift
import Supabase

class SupabaseService {
    static let shared = SupabaseService()
    
    private let client: SupabaseClient
    
    init() {
        client = SupabaseClient(
            supabaseURL: URL(string: "YOUR_SUPABASE_URL")!,
            supabaseKey: "YOUR_SUPABASE_ANON_KEY"
        )
    }
    
    // Paginazione messaggi
    func loadMessages(chatId: UUID, page: Int, pageSize: Int = 50) async throws -> [Message] {
        let response: [MessageRow] = try await client
            .from("messages")
            .select()
            .eq("chat_id", value: chatId)
            .order("timestamp", ascending: false)
            .range(from: page * pageSize, to: (page + 1) * pageSize - 1)
            .execute()
            .value
        
        return response.map { $0.toMessage() }
    }
    
    // Salvataggio con ottimizzazione
    func saveMessage(_ message: Message, toChatId chatId: UUID) async throws {
        let messageRow = MessageRow(from: message, chatId: chatId)
        
        try await client
            .from("messages")
            .insert(messageRow)
            .execute()
        
        // Aggiorna timestamp ultima attività
        try await client
            .from("chats")
            .update(["last_message_at": ISO8601DateFormatter().string(from: Date())])
            .eq("id", value: chatId)
            .execute()
    }
}
```

### 4. Realtime con WebSocket

```swift
class RealtimeChatService: ObservableObject {
    @Published var newMessages: [Message] = []
    private var subscription: RealtimeChannel?
    
    func subscribeToChat(_ chatId: UUID) {
        subscription = SupabaseService.shared.client
            .channel("chat_\(chatId)")
            .on(.insert, table: "messages") { [weak self] payload in
                if let messageData = payload.new,
                   let message = try? JSONDecoder().decode(MessageRow.self, from: messageData) {
                    DispatchQueue.main.async {
                        self?.newMessages.append(message.toMessage())
                    }
                }
            }
            .subscribe()
    }
    
    func unsubscribe() {
        subscription?.unsubscribe()
    }
}
```

## Implementazione Ibrida: CoreData + Supabase

### Strategia di Sincronizzazione

```swift
class HybridChatRepository: ChatRepositoryProtocol {
    private let coreDataStack: CoreDataStack
    private let supabaseService: SupabaseService
    private let syncManager: SyncManager
    
    func loadMessages(chatId: UUID, offset: Int, limit: Int) async -> [Message] {
        // 1. Carica da CoreData (cache locale)
        let localMessages = await loadLocalMessages(chatId: chatId, offset: offset, limit: limit)
        
        // 2. Se non ci sono abbastanza messaggi, carica da Supabase
        if localMessages.count < limit {
            do {
                let remoteMessages = try await supabaseService.loadMessages(
                    chatId: chatId, 
                    page: offset / limit
                )
                
                // 3. Salva in CoreData per cache
                await saveLocalMessages(remoteMessages, chatId: chatId)
                
                return remoteMessages
            } catch {
                // Fallback su dati locali
                return localMessages
            }
        }
        
        return localMessages
    }
    
    func saveMessage(_ message: Message, toChatId chatId: UUID) async {
        // 1. Salva immediatamente in CoreData
        await saveLocalMessage(message, chatId: chatId)
        
        // 2. Sincronizza con Supabase in background
        Task {
            do {
                try await supabaseService.saveMessage(message, toChatId: chatId)
                await markMessageAsSynced(message.id)
            } catch {
                await markMessageAsPendingSync(message.id)
            }
        }
    }
}
```

## Ottimizzazioni Performance

### 1. Memory Management
```swift
class MessageCache {
    private var cache: NSCache<NSString, NSArray> = {
        let cache = NSCache<NSString, NSArray>()
        cache.countLimit = 100 // Massimo 100 chat in cache
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB
        return cache
    }()
    
    func getMessages(for chatId: UUID) -> [Message]? {
        return cache.object(forKey: chatId.uuidString as NSString) as? [Message]
    }
    
    func setMessages(_ messages: [Message], for chatId: UUID) {
        let cost = messages.reduce(0) { $0 + $1.text.count }
        cache.setObject(messages as NSArray, forKey: chatId.uuidString as NSString, cost: cost)
    }
}
```

### 2. Background Sync
```swift
class BackgroundSyncManager {
    func scheduleSync() {
        let identifier = "com.agentchat.sync"
        let request = BGAppRefreshTaskRequest(identifier: identifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 minuti
        
        try? BGTaskScheduler.shared.submit(request)
    }
    
    func handleBackgroundSync() {
        Task {
            await syncPendingMessages()
            await downloadNewMessages()
        }
    }
}
```

## Vantaggi delle Soluzioni Proposte

### CoreData + Supabase
✅ **Offline-first**: Funziona senza connessione
✅ **Sync automatica**: Sincronizzazione bidirezionale
✅ **Performance**: Cache locale per accesso rapido
✅ **Scalabilità**: Database cloud per storage illimitato
✅ **Realtime**: Aggiornamenti in tempo reale

### Paginazione Intelligente
✅ **Memory efficiency**: Carica solo messaggi visibili
✅ **UX fluida**: Caricamento progressivo
✅ **Network optimization**: Riduce traffico dati

### Thread Persistence
✅ **Continuità**: Thread OpenAI persistenti
✅ **Security**: API keys in Keychain
✅ **Reliability**: Backup su cloud database

## Roadmap Implementazione

1. **Fase 1**: Setup CoreData + Repository pattern
2. **Fase 2**: Implementazione paginazione locale
3. **Fase 3**: Integrazione Supabase
4. **Fase 4**: Realtime WebSocket
5. **Fase 5**: Background sync e ottimizzazioni

Questa architettura risolve tutti i problemi identificati mantenendo l'app performante, scalabile e user-friendly.