//
//  AgentType.swift
//  AgentChat
//
//  Created by Mario Moschetta on 04/07/25.
//

import Foundation

// MARK: - AgentType Enum
enum AgentType: String, CaseIterable, Identifiable {
    case openAI = "OpenAI"
    case claude = "Claude"
    case mistral = "Mistral"
    case perplexity = "Perplexity"
    case grok = "Grok"
    case n8n = "n8n"
    case custom = "Custom"
    
    var id: String { rawValue }
}