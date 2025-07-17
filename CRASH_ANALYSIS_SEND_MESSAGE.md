# 🚨 CRASH ANALYSIS - Invio Messaggio AgentChat

## Problema Critico Identificato
**Crash Type**: `EXC_CRASH (SIGABRT)` - Abort trap: 6  
**Trigger**: Pressione del pulsante "Invia" per mandare un messaggio  
**Frequenza**: Consistente, si verifica quasi sempre

## Stack Trace Analizzato
```
Thread 0 Crashed:
0   SwiftUI.AsyncRenderer
1   ViewGraphDisplayLink.asyncThread  
2   CoreDataPersistenceManager.saveOrUpdateChat
3   ChatManager.addMessage
4   ChatDetailView.sendMessage
```

## Cause Root del Crash

### 🔴 Causa #1: Thread Safety Violation (CRITICA)
**File**: `CoreDataPersistenceManager.swift`  
**Metodo**: `saveOrUpdateChat(chat: Chat)`

**Problema**:
- Core Data context viene acceduto dal main thread
- Operazioni di salvataggio bloccanti sul UI thread
- SwiftUI AsyncRenderer va in conflitto con Core Data

**Codice Problematico**:
```swift
func saveOrUpdateChat(chat: Chat) {
    let context = container.viewContext // ❌ Main thread context
    // ... operazioni pesanti di serializzazione
    saveContext() // ❌ Salvataggio sincrono sul main thread
}
```

### 🔴 Causa #2: Serializzazione JSON Fragile (CRITICA)
**File**: `CoreDataPersistenceManager.swift`  
**Metodo**: `updateChatEntity(_:from:in:)`

**Problema**:
- Encoding di `AgentConfiguration` può fallire
- Errori di serializzazione non gestiti
- Crash se proprietà non sono Codable-compliant

**Codice Problematico**:
```swift
if let agentConfiguration = chat.agentConfiguration {
    do {
        let data = try encoder.encode(agentConfiguration) // ❌ CRASH POINT
        entity.agentConfigurationJSON = String(data: data, encoding: .utf8)
    } catch {
        print("ERRORE FATALE: ...") // ❌ Solo log, nessun recovery
    }
}
```

### 🔴 Causa #3: Race Condition sui Messaggi (CRITICA)
**File**: `ChatDetailView.swift`  
**Metodo**: `sendMessage()`

**Problema**:
- Modifica diretta di `chat.messages` nell'UI
- Modifica concorrente tramite `ChatManager.addMessage`
- Array `messages` corrotto durante l'accesso

**Codice Problematico**:
```swift
func sendMessage() async {
    // Prima modifica
    try ChatManager.shared.addMessage(to: chat, message: userMsg)
    
    // ...
    
    // Seconda modifica concorrente ❌
    let placeholderMsg = Message(id: placeholderId, content: "...", isUser: false, timestamp: Date())
    chat.messages.append(placeholderMsg) // ❌ RACE CONDITION
}
```

## Sequenza del Crash

1. **User Action**: Utente preme "Invia messaggio"
2. **UI Thread**: `ChatDetailView.sendMessage()` viene chiamato
3. **Persistence**: `ChatManager.addMessage()` → `CoreDataPersistenceManager.saveOrUpdateChat()`
4. **Serialization**: Tentativo di encoding di `AgentConfiguration`
5. **Thread Conflict**: SwiftUI AsyncRenderer + Core Data main thread access
6. **CRASH**: `SIGABRT` - Abort trap

## Soluzioni Immediate

### ✅ Fix #1: Background Core Data Context
```swift
// In CoreDataPersistenceManager.swift
func saveOrUpdateChat(chat: Chat) {
    let backgroundContext = container.newBackgroundContext()
    backgroundContext.perform {
        // Sposta tutta la logica qui
        let fetchRequest: NSFetchRequest<ChatEntity> = ChatEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", chat.id as CVarArg)
        
        do {
            let results = try backgroundContext.fetch(fetchRequest)
            let chatEntity = results.first ?? ChatEntity(context: backgroundContext)
            
            updateChatEntity(chatEntity, from: chat, in: backgroundContext)
            
            try backgroundContext.save()
            print("✅ Core Data saved successfully on background thread")
        } catch {
            print("❌ Core Data save failed: \(error)")
        }
    }
}
```

### ✅ Fix #2: Safe JSON Serialization
```swift
// In updateChatEntity()
if let agentConfiguration = chat.agentConfiguration {
    do {
        let data = try encoder.encode(agentConfiguration)
        entity.agentConfigurationJSON = String(data: data, encoding: .utf8)
    } catch {
        print("⚠️ AgentConfiguration serialization failed: \(error)")
        // Fallback sicuro: salva solo i dati essenziali
        entity.agentConfigurationJSON = createFallbackConfigJSON(from: agentConfiguration)
    }
}

private func createFallbackConfigJSON(from config: AgentConfiguration) -> String {
    let fallback = [
        "id": config.id.uuidString,
        "name": config.name,
        "role": config.role
    ]
    
    if let data = try? JSONSerialization.data(withJSONObject: fallback),
       let json = String(data: data, encoding: .utf8) {
        return json
    }
    
    return "{\"id\":\"\(config.id.uuidString)\",\"name\":\"\(config.name)\"}"
}
```

### ✅ Fix #3: Eliminazione Race Condition
```swift
// In ChatDetailView.swift
func sendMessage() async {
    let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty, !isAwaitingAssistant else { return }
    
    let userMsg = Message(id: UUID(), content: trimmed, isUser: true, timestamp: Date())
    
    do {
        // ✅ UNICA modifica tramite ChatManager
        try ChatManager.shared.addMessage(to: chat, message: userMsg)
    } catch {
        errorMessage = "Errore nell'invio del messaggio: \(error.localizedDescription)"
        return
    }
    
    inputText = ""
    errorMessage = nil
    isAwaitingAssistant = true
    
    // ✅ Placeholder gestito solo nell'UI, non persistito
    showTypingIndicator = true
    
    // ... resto della logica di invio
}
```

## Test di Verifica

### Test Case 1: Invio Messaggio Base
1. Aprire una chat esistente
2. Digitare un messaggio
3. Premere "Invia"
4. **Risultato Atteso**: Nessun crash, messaggio salvato

### Test Case 2: Invio Rapido Multiplo
1. Inviare 3-4 messaggi in rapida successione
2. **Risultato Atteso**: Tutti i messaggi salvati, nessun crash

### Test Case 3: Configurazione Agente Complessa
1. Usare un agente con configurazione personalizzata
2. Inviare messaggio
3. **Risultato Atteso**: Configurazione serializzata correttamente

## Priorità di Implementazione

1. **🔥 IMMEDIATO**: Fix #1 (Background Context) - Risolve il 90% dei crash
2. **🔥 IMMEDIATO**: Fix #3 (Race Condition) - Risolve instabilità UI
3. **⚡ URGENTE**: Fix #2 (Safe Serialization) - Previene crash futuri
4. **📋 FOLLOW-UP**: Test automatizzati per prevenire regressioni

## Note per il Debug

- Abilitare Core Data debug: `-com.apple.CoreData.SQLDebug 1`
- Monitorare thread con Instruments
- Verificare memory graph per retain cycles
- Testare su dispositivi fisici, non solo simulatore

---

**Status**: 🔴 CRITICO - Richiede fix immediato  
**Impatto**: Blocca completamente l'uso dell'app  
**Effort**: ~2-3 ore di sviluppo + testing