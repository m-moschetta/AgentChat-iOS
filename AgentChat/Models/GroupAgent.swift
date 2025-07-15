//
//  GroupAgent.swift
//  AgentChat
//
//  Created by Mario Moschetta on 04/07/25.
//

import Foundation

// MARK: - GroupAgent
struct GroupAgent: Codable, Hashable, Identifiable {
    let id = UUID()
    let name: String
    let role: String
    let personality: String
    let icon: String
    let systemPrompt: String
    let preferredProvider: AgentType
    
    // MARK: - Codable Implementation
    private enum CodingKeys: String, CodingKey {
        case name, role, personality, icon, systemPrompt, preferredProvider
        // id is excluded from coding - it will be generated automatically
    }
    
    // MARK: - Predefined Agents
    static let dataAnalyst = GroupAgent(
        name: "Data Analyst",
        role: "Analista Dati",
        personality: "Metodico, orientato ai dati, preciso nelle analisi",
        icon: "📊",
        systemPrompt: "Sei un analista dati esperto. Fornisci sempre analisi basate su dati concreti e statistiche. Sii preciso e metodico nelle tue valutazioni. Usa grafici e numeri quando possibile.",
        preferredProvider: .openAI
    )
    
    static let creativeDirector = GroupAgent(
        name: "Creative Director",
        role: "Direttore Creativo",
        personality: "Visionaria, creativa, pensa fuori dagli schemi",
        icon: "🎨",
        systemPrompt: "Sei un direttore creativo innovativo. Proponi sempre soluzioni creative e originali. Pensa fuori dagli schemi e non aver paura di idee audaci. Ispira con la tua visione.",
        preferredProvider: .claude
    )
    
    static let techLead = GroupAgent(
        name: "Tech Lead",
        role: "Lead Tecnico",
        personality: "Pragmatico, focalizzato su soluzioni tecniche efficienti",
        icon: "⚙️",
        systemPrompt: "Sei un tech lead esperto. Fornisci sempre soluzioni tecniche pragmatiche e fattibili. Considera performance, scalabilità e manutenibilità. Sii concreto e orientato all'implementazione.",
        preferredProvider: .openAI
    )
    
    static let strategist = GroupAgent(
        name: "Strategist",
        role: "Strategist",
        personality: "Business-oriented, visione a lungo termine",
        icon: "🎯",
        systemPrompt: "Sei uno strategist business. Pensa sempre al lungo termine e all'impatto sul business. Considera ROI, sostenibilità e crescita. Analizza il mercato e la concorrenza.",
        preferredProvider: .perplexity
    )
    
    static let critic = GroupAgent(
        name: "Critic",
        role: "Critico Costruttivo",
        personality: "Scettico costruttivo, trova problemi e limitazioni",
        icon: "🔍",
        systemPrompt: "Sei un critico costruttivo. Il tuo ruolo è trovare potenziali problemi e limitazioni nelle proposte. Sii scettico ma costruttivo, offrendo sempre alternative o miglioramenti.",
        preferredProvider: .claude
    )
    
    static let innovator = GroupAgent(
        name: "Innovator",
        role: "Innovatore",
        personality: "Esploratore di nuove tecnologie e tendenze",
        icon: "🚀",
        systemPrompt: "Sei un innovatore che esplora costantemente nuove tecnologie e tendenze. Proponi soluzioni all'avanguardia e identifica opportunità emergenti. Sii visionario ma realistico.",
        preferredProvider: .grok
    )
    
    static let securityExpert = GroupAgent(
        name: "Security Expert",
        role: "Esperto Sicurezza",
        personality: "Attento alla sicurezza, risk-averse, metodico",
        icon: "🛡️",
        systemPrompt: "Sei un esperto di sicurezza. Valuta sempre i rischi e le vulnerabilità. Proponi soluzioni sicure e conformi alle best practices. Considera privacy, compliance e protezione dati.",
        preferredProvider: .claude
    )
    
    // MARK: - All Agents
    static let allAgents: [GroupAgent] = [
        .dataAnalyst,
        .creativeDirector,
        .techLead,
        .strategist,
        .critic,
        .innovator,
        .securityExpert
    ]
    
    // MARK: - Methods
    func generateResponse(to message: String, context: [GroupMessage]) async throws -> String {
        let contextString = context.suffix(3).map { "\($0.sender.displayName): \($0.content)" }.joined(separator: "\n")
        
        let fullPrompt = """
        \(systemPrompt)
        
        Contesto conversazione:
        \(contextString)
        
        Rispondi come \(name) (\(role)) al seguente messaggio:
        \(message)
        
        Mantieni il tuo stile: \(personality)
        Rispondi in modo conciso ma completo (massimo 200 parole).
        """
        
        // Per ora usiamo un servizio mock, sarà sostituito con i servizi reali
        return try await MockAgentService.shared.generateResponse(fullPrompt, for: preferredProvider)
    }
}

// MARK: - Mock Service (temporaneo)
class MockAgentService {
    static let shared = MockAgentService()
    
    func generateResponse(_ prompt: String, for provider: AgentType) async throws -> String {
        // Simulazione risposta basata sul provider
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 secondo
        
        switch provider {
        case .openAI:
            return "[OpenAI] " + generateMockResponse(for: prompt)
        case .claude:
            return "[Claude] " + generateMockResponse(for: prompt)
        case .perplexity:
            return "[Perplexity] " + generateMockResponse(for: prompt)
        case .grok:
            return "[Grok] " + generateMockResponse(for: prompt)
        default:
            return "[Mock] " + generateMockResponse(for: prompt)
        }
    }
    
    private func generateMockResponse(for prompt: String) -> String {
        let responses = [
            "Interessante prospettiva. Basandomi sulla mia esperienza, suggerirei di considerare anche...",
            "Dal mio punto di vista, questo approccio presenta sia opportunità che sfide...",
            "Analizzando la situazione, ritengo che dovremmo focalizzarci su...",
            "La mia valutazione indica che questo potrebbe essere un punto di svolta...",
            "Considerando i fattori in gioco, la strategia migliore sarebbe..."
        ]
        return responses.randomElement() ?? "Risposta generata dal sistema."
    }
}