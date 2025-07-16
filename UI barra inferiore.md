# PIANO DI RISOLUZIONE ERRORI - AGENTCHAT

## STATO ATTUALE
- **Data**: 2025-01-27
- **Errori totali identificati**: ~20 file con errori di compilazione
- **Causa principale**: Refactoring incompleto delle strutture dati

## STRATEGIA DI RISOLUZIONE

### FASE 1: CORREZIONI STRUTTURALI CRITICHE (PRIORITÀ ALTA)

#### 1.1 Correzione AssistantProvider.rawValue
- **File**: AgentBridge.swift
- **Problema**: `AssistantProvider` è una struct, non ha `rawValue`
- **Soluzione**: Sostituire `provider.rawValue` con `provider.type.rawValue`
- **Status**: ✅ COMPLETATO - Errore risolto

#### 1.2 Correzione parametri mancanti in AgentSystemExamples.swift
- **Problema**: Argomento 'model' mancante nelle chiamate
- **Soluzione**: Aggiungere parametro model alle chiamate di funzione
- **Status**: ✅ COMPLETATO - Tutti gli errori risolti

#### 1.3 Correzione ChatService.swift
- **Problemi identificati**:
  - Switch must be exhaustive
  - Expression is 'async' but is not marked with 'await'
- **Status**: 🔄 IN CORSO

#### 1.4 Correzione GoogleGeminiAgentService.swift
- **Problemi multipli**:
  - Valore opzionale non unwrappato
  - Membri mancanti in AgentCapability
  - Argomento mancante per preferredProvider
  - Ordine errato parametri 'model' e 'messages'
- **Status**: ❌ DA FARE

### FASE 2: CORREZIONI API E PARAMETRI (PRIORITÀ MEDIA)

#### 2.1 Verifica e correzione signature delle funzioni
- **File**: Tutti i file con errori "missing argument"
- **Azione**: Verificare le signature aggiornate delle API
- **Status**: ❌ DA FARE

#### 2.2 Aggiornamento chiamate con parametri corretti
- **Azione**: Aggiungere parametri mancanti secondo le nuove API
- **Status**: ❌ DA FARE

### FASE 3: OTTIMIZZAZIONI E CLEANUP (PRIORITÀ BASSA)

#### 3.1 Risoluzione warning
- **File**: AgentMemoryManager.swift, AnthropicAgentService.swift
- **Status**: ❌ DA FARE

## BEST PRACTICES APPLICATE

### Da ricerca online:
1. **Enum vs Struct**: <mcreference link="https://medium.com/@kalidoss.shanmugam/swift-enums-best-practices-and-hidden-features-cdce09426c38" index="4">4</mcreference>
   - AssistantProvider è correttamente una struct (non enum)
   - Solo enum hanno rawValue, struct usano proprietà type.rawValue

2. **Swift 6.2 Changes**: <mcreference link="https://github.com/swiftlang/swift/blob/main/CHANGELOG.md" index="1">1</mcreference>
   - Verificare compatibilità con nuove API
   - Attenzione a cambiamenti in availability checking

3. **Error Handling**: <mcreference link="https://developer.apple.com/documentation/swift/error" index="5">5</mcreference>
   - Usare enum per errori semplici
   - Struct per errori complessi con dati aggiuntivi

## METODOLOGIA

### Approccio sistematico:
1. **Un file alla volta** - evitare modifiche multiple simultanee
2. **Test incrementale** - compilare dopo ogni correzione
3. **Documentazione** - aggiornare questo piano ad ogni step
4. **Rollback ready** - tenere traccia delle modifiche per eventuali rollback

## PROSSIMO STEP

**IMMEDIATO**: Iniziare con AgentBridge.swift (errore più semplice e critico)
- Sostituire `provider.rawValue` con `provider.type.rawValue`
- Compilare per verificare la correzione
- Aggiornare questo piano con il risultato

## LOG PROGRESSI

### 2025-01-27 - Inizio audit
- ✅ Audit errori completato
- ✅ Analisi strutture dati completata
- ✅ Ricerca best practice completata
- ✅ Piano creato
- ❌ Correzioni non ancora iniziate

---

**NOTA**: Questo piano verrà aggiornato dopo ogni correzione per tracciare i progressi e adattare la strategia se necessario.