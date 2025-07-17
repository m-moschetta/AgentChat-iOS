//
//  AgentType.swift
//  AgentChat
//
//  Created by Mario Moschetta on 04/07/25.
//

import Foundation

// MARK: - AgentType Enum
enum AgentType: String, CaseIterable, Identifiable, Codable {
    // Esistenti
    case openAI = "OpenAI"
    case claude = "Claude"
    case mistral = "Mistral"
    case perplexity = "Perplexity"
    case grok = "Grok"
    case deepSeek = "DeepSeek"
    case n8n = "n8n"
    case custom = "Custom"
    
    // Nuovi Multi-Agente
    case hybridMultiAgent = "Hybrid Multi-Agent"
    case agentGroup = "Agent Group"
    case group = "Group"
    case productTeam = "Product Team"
    case brainstormingSquad = "Brainstorming Squad"
    case codeReviewPanel = "Code Review Panel"
    
    var id: String { rawValue }
    
    var isMultiAgent: Bool {
        switch self {
        case .hybridMultiAgent, .agentGroup, .group, .productTeam, .brainstormingSquad, .codeReviewPanel:
            return true
        default:
            return false
        }
    }
    
    var displayName: String {
        switch self {
        case .openAI:
            return "OpenAI GPT"
        case .claude:
            return "Claude (Anthropic)"
        case .mistral:
            return "Mistral AI"
        case .perplexity:
            return "Perplexity"
        case .grok:
            return "Grok (X.AI)"
        case .deepSeek:
            return "DeepSeek AI"
        case .n8n:
            return "n8n Workflow"
        case .custom:
            return "Custom Provider"
        case .hybridMultiAgent:
            return "🤖 Hybrid Multi-Agent"
        case .agentGroup:
            return "👥 Agent Group"
        case .group:
            return "👥 Group"
        case .productTeam:
            return "🚀 Product Team"
        case .brainstormingSquad:
            return "💡 Brainstorming Squad"
        case .codeReviewPanel:
            return "🔍 Code Review Panel"
        }
    }
    
    var description: String {
        switch self {
        case .openAI:
            return "Modelli GPT di OpenAI per conversazioni generali"
        case .claude:
            return "Modelli Claude di Anthropic, ottimi per analisi e ragionamento"
        case .mistral:
            return "Modelli Mistral AI, efficienti e multilingue"
        case .perplexity:
            return "Modelli Perplexity con capacità di ricerca web"
        case .grok:
            return "Modelli Grok di X.AI con accesso a dati real-time"
        case .deepSeek:
            return "Modelli DeepSeek con capacità di ragionamento avanzato"
        case .n8n:
            return "Workflow personalizzati tramite n8n"
        case .custom:
            return "Provider personalizzato configurabile"
        case .hybridMultiAgent:
            return "Sistema ibrido che combina elaborazione locale e remota"
        case .agentGroup:
            return "Gruppo personalizzabile di agenti specializzati"
        case .group:
            return "Gruppo generico di agenti"
        case .productTeam:
            return "Team completo per sviluppo prodotto: strategia, design, tech e analisi"
        case .brainstormingSquad:
            return "Gruppo creativo per generazione idee innovative"
        case .codeReviewPanel:
            return "Panel di esperti per revisione codice e architettura"
        }
    }
    
    var icon: String {
        switch self {
        case .openAI:
            return "🤖"
        case .claude:
            return "🧠"
        case .mistral:
            return "⚡"
        case .perplexity:
            return "🔍"
        case .grok:
            return "🚀"
        case .deepSeek:
            return "🧠"
        case .n8n:
            return "⚙️"
        case .custom:
            return "🎛️"
        case .hybridMultiAgent:
            return "🤖"
        case .agentGroup:
            return "👥"
        case .group:
            return "👥"
        case .productTeam:
            return "🚀"
        case .brainstormingSquad:
            return "💡"
        case .codeReviewPanel:
            return "🔍"
        }
    }
    
    var iconName: String {
        switch self {
        case .openAI:
            return "brain.head.profile"
        case .claude:
            return "sparkles"
        case .mistral:
            return "wind"
        case .perplexity:
            return "magnifyingglass"
        case .grok:
            return "rocket"
        case .deepSeek:
            return "brain.head.profile"
        case .n8n:
            return "gearshape"
        case .custom:
            return "slider.horizontal.3"
        case .hybridMultiAgent:
            return "person.3"
        case .agentGroup:
            return "person.3.fill"
        case .group:
            return "person.3.fill"
        case .productTeam:
            return "rocket.fill"
        case .brainstormingSquad:
            return "lightbulb.fill"
        case .codeReviewPanel:
            return "magnifyingglass.circle.fill"
        }
    }
}