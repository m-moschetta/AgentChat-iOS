//
//  ServiceContainer.swift
//  AgentChat
//
//  Created by Mario Moschetta on 04/07/25.
//

import Foundation

// MARK: - Service Container Protocol
protocol ServiceContainerProtocol {
    func register<T>(_ type: T.Type, factory: @escaping () -> T)
    func resolve<T>(_ type: T.Type) -> T?
    func registerSingleton<T>(_ type: T.Type, factory: @escaping () -> T)
}

// MARK: - Service Container Implementation
class ServiceContainer: ServiceContainerProtocol {
    static let shared = ServiceContainer()
    
    private var services: [String: Any] = [:]
    private var singletons: [String: Any] = [:]
    private var factories: [String: () -> Any] = [:]
    
    private init() {
        registerDefaultServices()
    }
    
    // MARK: - Registration Methods
    func register<T>(_ type: T.Type, factory: @escaping () -> T) {
        let key = String(describing: type)
        factories[key] = factory
    }
    
    func registerSingleton<T>(_ type: T.Type, factory: @escaping () -> T) {
        let key = String(describing: type)
        factories[key] = factory
        // Don't create singleton immediately - use lazy initialization
    }
    
    // MARK: - Resolution Methods
    func resolve<T>(_ type: T.Type) -> T? {
        let key = String(describing: type)
        
        // Check if it's a singleton first
        if let singleton = singletons[key] as? T {
            return singleton
        }
        
        // Create singleton if factory exists and store it
        if let factory = factories[key] {
            let instance = factory() as? T
            if instance != nil {
                singletons[key] = instance
            }
            return instance
        }
        
        return nil
    }
    
    // MARK: - Default Service Registration
    private func registerDefaultServices() {
        // Register HTTP-based chat services (legacy)
        register(OpenAIService.self) { OpenAIService() }
        register(AnthropicService.self) { AnthropicService() }
        register(MistralService.self) { MistralService() }
        register(GrokService.self) { GrokService() }
        register(PerplexityService.self) { PerplexityService() }
        
        // Register new Agent Services
        register(OpenAIAgentService.self) { OpenAIAgentService() }
        register(AnthropicAgentService.self) { AnthropicAgentService() }
        register(MistralAgentService.self) { MistralAgentService() }
        register(GrokAgentService.self) { GrokAgentService() }
        register(PerplexityAgentService.self) { PerplexityAgentService() }
        register(DeepSeekAgentService.self) { DeepSeekAgentService() }
        register(N8NAgentService.self) { N8NAgentService() }
        register(CustomAgentService.self) { CustomAgentService() }
        
        // Register special services as singletons
        registerSingleton(N8NService.self) { N8NService.shared }
        registerSingleton(CustomProviderService.self) { CustomProviderService.shared }
        
        // Register multi-agent services as singletons
        registerSingleton(HybridMultiAgentService.self) { HybridMultiAgentService.shared }
        registerSingleton(GroupChatService.self) { GroupChatService.shared }
        
        // Register orchestrator as singleton
        registerSingleton(AgentOrchestrator.self) { AgentOrchestrator.shared }
        
        // Register managers (excluding ChatManager to avoid circular dependency)
        registerSingleton(KeychainService.self) { KeychainService.shared }
        registerSingleton(AgentMemoryManager.self) { AgentMemoryManager.shared }
        registerSingleton(AgentCollaborationManager.self) { AgentCollaborationManager.shared }
    }
}

// MARK: - Service Factory
class ServiceFactory {
    private let container: ServiceContainerProtocol
    
    init(container: ServiceContainerProtocol = ServiceContainer.shared) {
        self.container = container
    }
    
    // MARK: - Chat Service Creation (Legacy)
    func createChatService(for agentType: AgentType) -> ChatServiceProtocol? {
        switch agentType {
        case .openAI:
            return container.resolve(OpenAIService.self)
        case .claude:
            return container.resolve(AnthropicService.self)
        case .mistral:
            return container.resolve(MistralService.self)
        case .grok:
            return container.resolve(GrokService.self)
        case .perplexity:
            return container.resolve(PerplexityService.self)
        case .deepSeek:
            return nil // DeepSeek uses agent service only
        case .n8n:
            return container.resolve(N8NService.self)
        case .custom:
            return container.resolve(CustomProviderService.self)
        case .hybridMultiAgent:
            return container.resolve(HybridMultiAgentService.self)
        case .agentGroup:
            return container.resolve(GroupChatService.self)
        case .group:
            return container.resolve(GroupChatService.self)
        case .productTeam:
            return container.resolve(GroupChatService.self)
        case .brainstormingSquad:
            return container.resolve(GroupChatService.self)
        case .codeReviewPanel:
            return container.resolve(GroupChatService.self)
        }
    }
    
    // MARK: - Agent Service Creation (New)
    func createAgentService(for configuration: AgentConfiguration) -> AgentServiceProtocol? {
        switch configuration.preferredProvider.lowercased() {
        case "openai":
            return OpenAIAgentService(configuration: configuration)
        case "anthropic", "claude":
            return AnthropicAgentService(configuration: configuration)
        case "mistral":
            return MistralAgentService(configuration: configuration)
        case "grok":
            return GrokAgentService(configuration: configuration)
        case "perplexity":
            return PerplexityAgentService(configuration: configuration)
        case "deepseek":
            return DeepSeekAgentService(configuration: configuration)
        case "n8n":
            return N8NAgentService(configuration: configuration)
        default:
            return CustomAgentService(configuration: configuration, customConfig: nil)
        }
    }
    
    func createAgentService(for agentType: AgentType, configuration: AgentConfiguration? = nil) -> AgentServiceProtocol? {
        switch agentType {
        case .openAI:
            return OpenAIAgentService(configuration: configuration)
        case .claude:
            return AnthropicAgentService(configuration: configuration)
        case .mistral:
            return MistralAgentService(configuration: configuration)
        case .grok:
            return GrokAgentService(configuration: configuration)
        case .perplexity:
            return PerplexityAgentService(configuration: configuration)
        case .deepSeek:
            return DeepSeekAgentService(configuration: configuration)
        case .n8n:
            return N8NAgentService(configuration: configuration)
        case .custom:
            return CustomAgentService(configuration: configuration, customConfig: nil)
        case .hybridMultiAgent:
            return container.resolve(HybridMultiAgentService.self) as? AgentServiceProtocol
        case .agentGroup, .group, .productTeam, .brainstormingSquad, .codeReviewPanel:
            return container.resolve(GroupChatService.self) as? AgentServiceProtocol
        }
    }
    
    func createChatService(for provider: String) -> ChatServiceProtocol? {
        switch provider.lowercased() {
        case "openai":
            return container.resolve(OpenAIService.self)
        case "anthropic", "claude":
            return container.resolve(AnthropicService.self)
        case "mistral":
            return container.resolve(MistralService.self)
        case "grok":
            return container.resolve(GrokService.self)
        case "perplexity":
            return container.resolve(PerplexityService.self)
        case "n8n":
            return container.resolve(N8NService.self)
        case "custom":
            return container.resolve(CustomProviderService.self)
        default:
            return nil
        }
    }
}

// MARK: - Dependency Injection Extensions
extension ServiceContainer {
    // Convenience methods for common services
    var keychainService: KeychainService? {
        return resolve(KeychainService.self)
    }
    
    var agentMemoryManager: AgentMemoryManager? {
        return resolve(AgentMemoryManager.self)
    }
    
    var agentOrchestrator: AgentOrchestrator? {
        return resolve(AgentOrchestrator.self)
    }
    
    var collaborationManager: AgentCollaborationManager? {
        return resolve(AgentCollaborationManager.self)
    }
}

// MARK: - Service Locator Pattern (for backward compatibility)
class ServiceLocator {
    static let shared = ServiceLocator()
    private let serviceFactory = ServiceFactory()
    
    private init() {}
    
    func getChatService(for agentType: AgentType) -> ChatServiceProtocol? {
        return serviceFactory.createChatService(for: agentType)
    }
    
    func getChatService(for provider: String) -> ChatServiceProtocol? {
        return serviceFactory.createChatService(for: provider)
    }
    
    func getAgentService(for configuration: AgentConfiguration) -> AgentServiceProtocol? {
        return serviceFactory.createAgentService(for: configuration)
    }
    
    func getAgentOrchestrator() -> AgentOrchestrator? {
        return ServiceContainer.shared.agentOrchestrator
    }
}