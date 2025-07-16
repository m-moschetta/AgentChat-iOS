//
//  AgentSystemExamples.swift
//  AgentChat
//
//  Created by Assistant on 2024.
//

import Foundation

// MARK: - Agent System Usage Examples

/// Esempi di utilizzo del nuovo sistema di agenti
class AgentSystemExamples {
    
    // MARK: - Single Agent Examples
    
    /// Esempio di utilizzo di un singolo agente OpenAI
    static func singleOpenAIAgentExample() async {
        // Crea una configurazione per un agente OpenAI
        let config = AgentConfiguration.createAgentConfiguration(
            name: "Assistente OpenAI",
            agentType: .openAI,
            model: "gpt-4",
            systemPrompt: "Sei un assistente AI esperto in programmazione Swift e iOS.",
            capabilities: [.textGeneration, .codeGeneration, .dataAnalysis],
            parameters: nil
        )
        
        // Ottieni il servizio agente
        guard let agentService = ChatManager.shared.getAgentService(for: config) else {
            print("Errore: impossibile creare il servizio agente")
            return
        }
        
        // Invia un messaggio
        do {
            let response = try await agentService.sendMessage(
                "Scrivi una funzione Swift per calcolare il fattoriale di un numero",
                model: nil
            )
            print("Risposta: \(response)")
        } catch {
            print("Errore nell'invio del messaggio: \(error)")
        }
    }
    
    /// Esempio di utilizzo di un agente Perplexity per ricerca
    static func perplexityResearchExample() async {
        let config = AgentConfiguration.createAgentConfiguration(
            name: "Ricercatore Perplexity",
            agentType: .perplexity,
            model: nil,
            systemPrompt: "Sei un ricercatore esperto. Fornisci informazioni accurate e aggiornate.",
            capabilities: [.textGeneration, .webSearch, .dataAnalysis],
            parameters: nil
        )
        
        guard let agentService = ChatManager.shared.getAgentService(for: config) else {
            print("Errore: impossibile creare il servizio agente")
            return
        }
        
        do {
            let response = try await agentService.sendMessage(
                "Quali sono le ultime novità nel campo dell'intelligenza artificiale?",
                model: nil
            )
            print("Ricerca: \(response)")
        } catch {
            print("Errore nella ricerca: \(error)")
        }
    }
    
    // MARK: - Multi-Agent Examples
    
    /// Esempio di collaborazione tra più agenti
    static func multiAgentCollaborationExample() async {
        let orchestrator = ChatManager.shared.getAgentOrchestrator()
        
        // Configura gli agenti
        let researcher = AgentConfiguration.createAgentConfiguration(
            name: "Ricercatore",
            agentType: .perplexity,
            model: nil,
            systemPrompt: "Sei un ricercatore. Raccogli informazioni accurate e dettagliate.",
            capabilities: [],
            parameters: nil
        )
        
        let analyst = AgentConfiguration.createAgentConfiguration(
            name: "Analista",
            agentType: .claude,
            model: nil,
            systemPrompt: "Sei un analista. Analizza le informazioni e fornisci insight.",
            capabilities: [],
            parameters: nil
        )
        
        let writer = AgentConfiguration.createAgentConfiguration(
            name: "Scrittore",
            agentType: .openAI,
            model: nil,
            systemPrompt: "Sei uno scrittore. Crea contenuti ben strutturati e coinvolgenti.",
            capabilities: [],
            parameters: nil
        )
        
        // Crea una sessione multi-agente
        let groupConfig = AgentConfiguration.createAgentConfiguration(
            name: "Group",
            agentType: .openAI,
            model: nil,
            systemPrompt: "Group session",
            capabilities: [],
            parameters: nil
        )
guard let session = try? orchestrator.createSession(for: groupConfig.id, chatId: UUID(), sessionType: .group) else {
            print("Errore: impossibile creare la sessione multi-agente")
            return
        }
        
        let sessionId = session.id
        
        // Invia un task collaborativo
        do {
            let result = try await orchestrator.processMessage(
                "Crea un report completo sulle tendenze dell'AI nel 2024",
                for: sessionId
            )
            print("Risultato collaborativo: \(result)")
        } catch {
            print("Errore nel task collaborativo: \(error)")
        }
        
        // Termina la sessione
        // Session cleanup handled automatically
    }
    
    /// Esempio di task parallelo
    static func parallelTaskExample() async {
        let orchestrator = ChatManager.shared.getAgentOrchestrator()
        
        // Configura agenti specializzati
        let coder = AgentConfiguration.createAgentConfiguration(
            name: "Programmatore",
            agentType: .claude,
            model: "claude-3-5-sonnet-20241022",
            systemPrompt: "Sei un programmatore esperto in Swift e iOS.",
            capabilities: [.codeGeneration, .dataAnalysis],
            parameters: nil
        )
        
        let designer = AgentConfiguration.createAgentConfiguration(
            name: "Designer",
            agentType: .openAI,
            model: nil,
            systemPrompt: "Sei un designer UX/UI esperto.",
            capabilities: [.textGeneration, .dataAnalysis],
            parameters: nil
        )
        
        let tester = AgentConfiguration.createAgentConfiguration(
            name: "Tester",
            agentType: .mistral,
            model: nil,
            systemPrompt: "Sei un tester esperto in quality assurance.",
            capabilities: [.dataAnalysis],
            parameters: nil
        )
        
        // Crea sessione per task parallelo
        guard let session = try? orchestrator.createSession(for: coder.id, chatId: UUID(), sessionType: .group) else {
            print("Errore: impossibile creare la sessione parallela")
            return
        }
        
        let sessionId = session.id
        
        do {
            let result = try await orchestrator.processMessage(
                "Sviluppa una nuova feature per l'app: sistema di notifiche push",
                for: sessionId
            )
            print("Risultato parallelo: \(result)")
        } catch {
            print("Errore nel task parallelo: \(error)")
        }
        
        orchestrator.endSession(sessionId)
    }
    
    // MARK: - Memory Management Examples
    
    /// Esempio di gestione della memoria conversazionale
    static func memoryManagementExample() async {
        let config = AgentConfiguration.createAgentConfiguration(
            name: "Assistente con Memoria",
            agentType: .openAI,
            model: nil,
            systemPrompt: "Sei un assistente che ricorda le conversazioni precedenti.",
            capabilities: [.textGeneration],
            parameters: AgentParameters(
                temperature: 0.7,
                maxTokens: 1000,
                timeout: 30.0,
                retryAttempts: 3
            )
        )
        
        guard let agentService = ChatManager.shared.getAgentService(for: config) else {
            print("Errore: impossibile creare il servizio agente")
            return
        }
        
        // Primo messaggio
        do {
            let response1 = try await agentService.sendMessage("Il mio nome è Mario e sto lavorando su un'app iOS", model: nil)
            print("Risposta 1: \(response1)")
            
            // Salva il contesto
            let context = ConversationContext(
                chatId: UUID(),
                agentId: config.id
            )
            
            try await agentService.saveConversationContext(context)
            
            // Secondo messaggio che fa riferimento al primo
            let response2 = try await agentService.sendMessage("Puoi aiutarmi con il design pattern MVVM per la mia app?", model: nil)
            print("Risposta 2: \(response2)")
            
        } catch {
            print("Errore nella gestione della memoria: \(error)")
        }
    }
    
    // MARK: - Custom Agent Examples
    
    /// Esempio di agente personalizzato
    static func customAgentExample() async {
        // Crea una configurazione personalizzata
        var customConfig = AgentConfiguration.createAgentConfiguration(
            name: "Agente Personalizzato",
            agentType: .openAI,
            model: nil,
            systemPrompt: "Sei un assistente specializzato in marketing digitale.",
            capabilities: [],
            parameters: nil
        )
        
        // Aggiungi configurazioni personalizzate
        customConfig.customConfig = [
            "api_endpoint": "https://api.custom-provider.com/v1/chat",
            "api_version": "v1",
            "custom_parameter": "marketing_specialist"
        ]
        
        guard let agentService = ChatManager.shared.getAgentService(for: customConfig) else {
            print("Errore: impossibile creare il servizio agente personalizzato")
            return
        }
        
        do {
            let response = try await agentService.sendMessage("Crea una strategia di marketing per un'app mobile", model: nil)
            print("Risposta personalizzata: \(response)")
        } catch {
            print("Errore nell'agente personalizzato: \(error)")
        }
    }
    
    // MARK: - N8N Workflow Examples
    
    /// Esempio di integrazione con N8N
    static func n8nWorkflowExample() async {
        let config = AgentConfiguration.createAgentConfiguration(
            name: "Agente N8N",
            agentType: .openAI,
            model: nil,
            systemPrompt: "Sei un agente che gestisce workflow di automazione.",
            capabilities: [],
            parameters: nil
        )
        
        guard let agentService = ChatManager.shared.getAgentService(for: config) as? N8NAgentService else {
            print("Errore: impossibile creare il servizio N8N")
            return
        }
        
        do {
            // Esegui un workflow
            let workflowResult = try await agentService.executeWorkflow(
                workflowId: "email-automation",
                input: ["recipient": "user@example.com", "subject": "Benvenuto!"]
            )
            print("Risultato workflow: \(workflowResult)")
            
            // Lista i workflow disponibili
            let workflows = try await agentService.listWorkflows()
            print("Workflow disponibili: \(workflows)")
            
        } catch {
            print("Errore nel workflow N8N: \(error)")
        }
    }
    
    // MARK: - Error Handling Examples
    
    /// Esempio di gestione degli errori
    static func errorHandlingExample() async {
        let config = AgentConfiguration.createAgentConfiguration(
            name: "Test Errori",
            agentType: .openAI,
            model: "modello-inesistente", // Modello non valido per testare gli errori
            systemPrompt: "Test per gestione errori",
            capabilities: [],
            parameters: nil
        )
        
        guard let agentService = ChatManager.shared.getAgentService(for: config) else {
            print("Errore: impossibile creare il servizio agente")
            return
        }
        
        do {
            // Testa la validazione della configurazione
            _ = try await agentService.validateConfiguration()
            print("Configurazione valida")
        } catch let error as AgentServiceError {
            switch error {
            case .invalidConfiguration(let message):
                print("Configurazione non valida: \(message)")
            case .networkError(let networkError):
                print("Errore di rete: \(networkError.localizedDescription)")
            case .memoryError(let message):
                print("Errore di memoria: \(message)")
            case .missingConfiguration:
                print("Configurazione mancante")
            case .collaborationNotSupported:
                print("Collaborazione non supportata")
            case .notImplemented:
                print("Metodo non implementato")
            }
        } catch {
            print("Errore generico: \(error)")
        }
    }
    
    // MARK: - Performance Examples
    
    /// Esempio di monitoraggio delle performance
    static func performanceMonitoringExample() async {
        let config = AgentConfiguration.createAgentConfiguration(
            name: "Test Performance",
            agentType: .openAI,
            model: nil,
            systemPrompt: "Test di performance",
            capabilities: [.textGeneration],
            parameters: AgentParameters(
                temperature: 0.7,
                maxTokens: 1000,
                timeout: 10.0, // Timeout ridotto per test
                retryAttempts: 2
            )
        )
        
        guard let agentService = ChatManager.shared.getAgentService(for: config) else {
            print("Errore: impossibile creare il servizio agente")
            return
        }
        
        let startTime = Date()
        
        do {
            let response = try await agentService.sendMessage("Spiega brevemente cos'è l'intelligenza artificiale", model: nil)
            
            let endTime = Date()
            let duration = endTime.timeIntervalSince(startTime)
            
            print("Risposta ricevuta in \(duration) secondi")
            print("Lunghezza risposta: \(response.count) caratteri")
            print("Risposta: \(response)")
            
        } catch {
            let endTime = Date()
            let duration = endTime.timeIntervalSince(startTime)
            print("Errore dopo \(duration) secondi: \(error)")
        }
    }
}

// MARK: - Usage Helper

/// Helper per eseguire tutti gli esempi
class AgentExamplesRunner {
    static func runAllExamples() async {
        print("=== Esempi del Sistema di Agenti ===")
        
        print("\n1. Agente Singolo OpenAI:")
        await AgentSystemExamples.singleOpenAIAgentExample()
        
        print("\n2. Ricerca con Perplexity:")
        await AgentSystemExamples.perplexityResearchExample()
        
        print("\n3. Collaborazione Multi-Agente:")
        await AgentSystemExamples.multiAgentCollaborationExample()
        
        print("\n4. Task Parallelo:")
        await AgentSystemExamples.parallelTaskExample()
        
        print("\n5. Gestione Memoria:")
        await AgentSystemExamples.memoryManagementExample()
        
        print("\n6. Agente Personalizzato:")
        await AgentSystemExamples.customAgentExample()
        
        print("\n7. Workflow N8N:")
        await AgentSystemExamples.n8nWorkflowExample()
        
        print("\n8. Gestione Errori:")
        await AgentSystemExamples.errorHandlingExample()
        
        print("\n9. Monitoraggio Performance:")
        await AgentSystemExamples.performanceMonitoringExample()
        
        print("\n=== Fine Esempi ===")
    }
}