//
//  AgentOrchestrator.swift
//  AgentChat
//
//  Created by Mario Moschetta on 04/07/25.
//

import Foundation
import Combine

// MARK: - Agent Orchestrator
class AgentOrchestrator: ObservableObject {
    static let shared = AgentOrchestrator()
    
    // MARK: - Properties
    @Published var activeAgents: [UUID: AgentServiceProtocol] = [:]
    @Published var activeSessions: [UUID: AgentSession] = [:]
    @Published var collaborativeTasks: [UUID: CollaborativeTask] = [:]
    
    private let serviceFactory = ServiceFactory()
    private let configurationManager = AgentConfigurationManager.shared
    private let taskQueue = DispatchQueue(label: "agent.orchestrator", qos: .userInitiated)
    
    private init() {}
    
    // MARK: - Agent Management
    func createAgentService(for configuration: AgentConfiguration) throws -> AgentServiceProtocol {
        let agentService: AgentServiceProtocol
        
        switch configuration.preferredProvider.lowercased() {
        case "openai":
            agentService = OpenAIAgentService(configuration: configuration)
        case "anthropic", "claude":
            agentService = AnthropicAgentService(configuration: configuration)
        case "mistral":
            agentService = MistralAgentService(configuration: configuration)
        case "perplexity":
            agentService = PerplexityAgentService(configuration: configuration)
        case "grok":
            agentService = GrokAgentService(configuration: configuration)
        case "n8n":
            agentService = N8NAgentService(configuration: configuration)
        default:
            agentService = CustomAgentService(configuration: configuration)
        }
        
        activeAgents[configuration.id] = agentService
        return agentService
    }
    
    func getAgentService(for agentId: UUID) -> AgentServiceProtocol? {
        return activeAgents[agentId]
    }
    
    func removeAgentService(for agentId: UUID) {
        activeAgents.removeValue(forKey: agentId)
        
        // Rimuovi anche le sessioni associate
        activeSessions = activeSessions.filter { $0.value.agentId != agentId }
    }
    
    // MARK: - Session Management
    func createSession(for agentId: UUID, chatId: UUID, sessionType: SessionType = .single) throws -> AgentSession {
        if activeAgents[agentId] == nil {
            // Prova a creare il servizio se non esiste
            guard let configuration = configurationManager.getAgent(withId: agentId) else {
                throw OrchestratorError.agentNotFound(agentId)
            }
            let service = try createAgentService(for: configuration)
            activeAgents[agentId] = service
        }
        
        let session = AgentSession(
            agentId: agentId,
            chatId: chatId,
            sessionType: sessionType
        )
        
        activeSessions[session.id] = session
        return session
    }
    
    func getSession(for sessionId: UUID) -> AgentSession? {
        return activeSessions[sessionId]
    }
    
    func endSession(_ sessionId: UUID) {
        activeSessions.removeValue(forKey: sessionId)
    }
    
    // MARK: - Message Processing
    func processMessage(
        _ message: String,
        for sessionId: UUID,
        model: String? = nil
    ) async throws -> String {
        guard let session = activeSessions[sessionId] else {
            throw OrchestratorError.sessionNotFound(sessionId)
        }
        
        guard let agentService = activeAgents[session.agentId] else {
            throw OrchestratorError.agentNotFound(session.agentId)
        }
        
        // Aggiorna la sessione
        session.lastActivity = Date()
        session.messageCount += 1
        
        // Processa il messaggio
        let response = try await agentService.sendMessage(message, model: model)
        
        // Aggiorna le statistiche
        session.totalTokensUsed += estimateTokens(message + response)
        
        return response
    }
    
    // MARK: - Collaborative Task Management
    func createCollaborativeTask(
        _ task: CollaborativeTask
    ) async throws -> UUID {
        collaborativeTasks[task.id] = task
        
        // Avvia il task in background
        Task {
            await executeCollaborativeTask(task.id)
        }
        
        return task.id
    }
    
    func getCollaborativeTask(_ taskId: UUID) -> CollaborativeTask? {
        return collaborativeTasks[taskId]
    }
    
    private func executeCollaborativeTask(_ taskId: UUID) async {
        guard let task = collaborativeTasks[taskId] else { return }
        
        do {
            // Aggiorna lo stato del task
            task.status = .running
            task.startTime = Date()
            
            // Esegui il task basandosi sul tipo
            switch task.type {
            case .sequential:
                try await executeSequentialTask(task)
            case .parallel:
                await executeParallelTask(task)
            case .collaborative:
                try await executeCollaborativeWorkflow(task)
            }
            
            task.status = .completed
            task.endTime = Date()
            
        } catch {
            task.status = .failed
            task.error = error.localizedDescription
            task.endTime = Date()
        }
    }
    
    private func executeSequentialTask(_ task: CollaborativeTask) async throws {
        var currentResult = task.initialInput
        
        for step in task.steps {
            guard let agentService = activeAgents[step.agentId] else {
                throw OrchestratorError.agentNotFound(step.agentId)
            }
            
            let stepInput = buildStepInput(currentResult, step: step)
            currentResult = try await agentService.sendMessage(stepInput, model: step.preferredModel)
            
            // Aggiorna il progresso
            task.progress = Float(task.steps.firstIndex(of: step)! + 1) / Float(task.steps.count)
        }
        
        task.result = currentResult
    }
    
    private func executeParallelTask(_ task: CollaborativeTask) async {
        let results = await withTaskGroup(of: (Int, String).self) { group in
            for (index, step) in task.steps.enumerated() {
                group.addTask {
                    guard let agentService = self.activeAgents[step.agentId] else {
                        return (index, "Error: Agent not found")
                    }
                    
                    do {
                        let stepInput = self.buildStepInput(task.initialInput, step: step)
                        let result = try await agentService.sendMessage(stepInput, model: step.preferredModel)
                        return (index, result)
                    } catch {
                        return (index, "Error: \(error.localizedDescription)")
                    }
                }
            }
            
            var results: [(Int, String)] = []
            for await result in group {
                results.append(result)
            }
            return results.sorted { $0.0 < $1.0 }
        }
        
        // Combina i risultati
        let combinedResult = results.map { $0.1 }.joined(separator: "\n\n---\n\n")
        task.result = combinedResult
        task.progress = 1.0
    }
    
    private func executeCollaborativeWorkflow(_ task: CollaborativeTask) async throws {
        // Implementazione più complessa per workflow collaborativi
        // Sarà estesa nelle fasi successive
        try await executeSequentialTask(task)
    }
    
    private func buildStepInput(_ previousResult: String, step: TaskStep) -> String {
        var input = ""
        
        if !step.instruction.isEmpty {
            input += "Instruction: \(step.instruction)\n\n"
        }
        
        if !previousResult.isEmpty {
            input += "Previous result: \(previousResult)\n\n"
        }
        
        input += "Please process this information according to your role and capabilities."
        
        return input
    }
    
    // MARK: - Utility Methods
    private func estimateTokens(_ text: String) -> Int {
        // Stima approssimativa: ~4 caratteri per token
        return text.count / 4
    }
    
    func getActiveAgentCount() -> Int {
        return activeAgents.count
    }
    
    func getActiveSessionCount() -> Int {
        return activeSessions.count
    }
    
    func getActiveTaskCount() -> Int {
        return collaborativeTasks.values.filter { $0.status == .running }.count
    }
    
    // MARK: - Cleanup
    func cleanupInactiveSessions() {
        let cutoffTime = Date().addingTimeInterval(-3600) // 1 ora fa
        
        activeSessions = activeSessions.filter { _, session in
            session.lastActivity > cutoffTime
        }
    }
    
    func cleanupCompletedTasks() {
        let cutoffTime = Date().addingTimeInterval(-86400) // 24 ore fa
        
        collaborativeTasks = collaborativeTasks.filter { _, task in
            guard let endTime = task.endTime else { return true }
            return endTime > cutoffTime
        }
    }
}

// MARK: - Agent Session
class AgentSession: ObservableObject, Identifiable {
    let id = UUID()
    let agentId: UUID
    let chatId: UUID
    let sessionType: SessionType
    let createdAt: Date
    
    @Published var lastActivity: Date
    @Published var messageCount: Int = 0
    @Published var totalTokensUsed: Int = 0
    @Published var isActive: Bool = true
    
    init(agentId: UUID, chatId: UUID, sessionType: SessionType) {
        self.agentId = agentId
        self.chatId = chatId
        self.sessionType = sessionType
        self.createdAt = Date()
        self.lastActivity = Date()
    }
}

enum SessionType {
    case single
    case group
    case collaborative
}

// MARK: - Collaborative Task
class CollaborativeTask: ObservableObject, Identifiable {
    let id = UUID()
    let name: String
    let type: TaskExecutionType
    let steps: [TaskStep]
    let initialInput: String
    
    @Published var status: TaskStatus = .pending
    @Published var progress: Float = 0.0
    @Published var result: String = ""
    @Published var error: String?
    
    var startTime: Date?
    var endTime: Date?
    
    init(name: String, type: TaskExecutionType, steps: [TaskStep], initialInput: String) {
        self.name = name
        self.type = type
        self.steps = steps
        self.initialInput = initialInput
    }
}

struct TaskStep: Identifiable, Equatable {
    let id = UUID()
    let agentId: UUID
    let instruction: String
    let preferredModel: String?
    let timeout: TimeInterval
    
    init(agentId: UUID, instruction: String, preferredModel: String? = nil, timeout: TimeInterval = 60) {
        self.agentId = agentId
        self.instruction = instruction
        self.preferredModel = preferredModel
        self.timeout = timeout
    }
    
    static func == (lhs: TaskStep, rhs: TaskStep) -> Bool {
        return lhs.id == rhs.id
    }
}

enum TaskExecutionType {
    case sequential  // Esegui step uno dopo l'altro
    case parallel    // Esegui tutti gli step in parallelo
    case collaborative // Workflow collaborativo complesso
}

enum TaskStatus {
    case pending
    case running
    case completed
    case failed
    case cancelled
}

// MARK: - Orchestrator Errors
enum OrchestratorError: LocalizedError {
    case agentNotFound(UUID)
    case sessionNotFound(UUID)
    case taskNotFound(UUID)
    case invalidConfiguration
    case collaborationFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .agentNotFound(let id):
            return "Agent with ID \(id) not found"
        case .sessionNotFound(let id):
            return "Session with ID \(id) not found"
        case .taskNotFound(let id):
            return "Task with ID \(id) not found"
        case .invalidConfiguration:
            return "Invalid orchestrator configuration"
        case .collaborationFailed(let reason):
            return "Collaboration failed: \(reason)"
        }
    }
}

// MARK: - Agent Services
// Tutti gli AgentService sono implementati nei loro file dedicati:
// - AnthropicAgentService.swift
// - MistralAgentService.swift
// - PerplexityAgentService.swift
// - GrokAgentService.swift
// - N8NAgentService.swift
// - CustomAgentService.swift