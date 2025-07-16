//
//  AgentGroupTemplate.swift
//  AgentChat
//
//  Created by Mario Moschetta on 04/07/25.
//

import Foundation

// MARK: - AgentGroupTemplate
struct AgentGroupTemplate: Identifiable, Codable {
    let id = UUID()
    let name: String
    let description: String
    let icon: String
    let participants: [GroupAgent]
    let agentType: AgentType
    let useCases: [String]
    
    // MARK: - Predefined Templates
    static let productTeam = AgentGroupTemplate(
        name: "Product Development Team",
        description: "Team completo per sviluppo prodotto: strategia, design, tech e analisi",
        icon: "🚀",
        participants: [
            .strategist,
            .techLead,
            .creativeDirector,
            .dataAnalyst,
            .critic
        ],
        agentType: .productTeam,
        useCases: [
            "Pianificazione roadmap prodotto",
            "Analisi requisiti e specifiche",
            "Valutazione fattibilità tecnica",
            "Design dell'esperienza utente",
            "Analisi competitive"
        ]
    )
    
    static let brainstormingSquad = AgentGroupTemplate(
        name: "Brainstorming Squad",
        description: "Gruppo creativo per generazione idee innovative",
        icon: "💡",
        participants: [
            .creativeDirector,
            .innovator,
            .strategist,
            .critic
        ],
        agentType: .brainstormingSquad,
        useCases: [
            "Generazione idee creative",
            "Risoluzione problemi complessi",
            "Esplorazione nuove opportunità",
            "Design thinking sessions",
            "Innovazione di processo"
        ]
    )
    
    static let codeReviewPanel = AgentGroupTemplate(
        name: "Code Review Panel",
        description: "Panel di esperti per revisione codice e architettura",
        icon: "🔍",
        participants: [
            .techLead,
            .securityExpert,
            .critic,
            .dataAnalyst
        ],
        agentType: .codeReviewPanel,
        useCases: [
            "Revisione codice e architettura",
            "Analisi sicurezza e vulnerabilità",
            "Ottimizzazione performance",
            "Best practices e standard",
            "Refactoring e miglioramenti"
        ]
    )
    
    static let businessAnalysisTeam = AgentGroupTemplate(
        name: "Business Analysis Team",
        description: "Team per analisi business e decisioni strategiche",
        icon: "📈",
        participants: [
            .strategist,
            .dataAnalyst,
            .critic,
            .innovator
        ],
        agentType: .agentGroup,
        useCases: [
            "Analisi di mercato",
            "Valutazione investimenti",
            "Pianificazione strategica",
            "Analisi competitor",
            "Previsioni e trend"
        ]
    )
    
    static let designThinkingTeam = AgentGroupTemplate(
        name: "Design Thinking Team",
        description: "Team multidisciplinare per design thinking e UX",
        icon: "🎨",
        participants: [
            .creativeDirector,
            .dataAnalyst,
            .techLead,
            .critic
        ],
        agentType: .agentGroup,
        useCases: [
            "User experience design",
            "Prototipazione rapida",
            "User research e testing",
            "Design system",
            "Accessibilità e usabilità"
        ]
    )
    
    static let securityAuditTeam = AgentGroupTemplate(
        name: "Security Audit Team",
        description: "Team specializzato in sicurezza e compliance",
        icon: "🛡️",
        participants: [
            .securityExpert,
            .techLead,
            .critic,
            .dataAnalyst
        ],
        agentType: .agentGroup,
        useCases: [
            "Audit di sicurezza",
            "Valutazione vulnerabilità",
            "Compliance e normative",
            "Incident response",
            "Security by design"
        ]
    )
    
    // MARK: - All Templates
    static let allTemplates: [AgentGroupTemplate] = [
        .productTeam,
        .brainstormingSquad,
        .codeReviewPanel,
        .businessAnalysisTeam,
        .designThinkingTeam,
        .securityAuditTeam
    ]
    
    // MARK: - Template Categories
    static let developmentTemplates: [AgentGroupTemplate] = [
        .productTeam,
        .codeReviewPanel,
        .designThinkingTeam
    ]
    
    static let businessTemplates: [AgentGroupTemplate] = [
        .businessAnalysisTeam,
        .brainstormingSquad
    ]
    
    static let securityTemplates: [AgentGroupTemplate] = [
        .securityAuditTeam
    ]
    
    // MARK: - Methods
    func createGroup() -> AgentGroup {
        return AgentGroup(
            name: name,
            description: description,
            icon: icon,
            participants: participants,
            agentType: agentType
        )
    }
    
    var participantCount: Int {
        return participants.count
    }
    
    var participantNames: String {
        return participants.map { $0.name }.joined(separator: ", ")
    }
    
    var category: TemplateCategory {
        switch agentType {
        case .productTeam, .codeReviewPanel:
            return .development
        case .brainstormingSquad:
            return .creative
        default:
            if participants.contains(where: { $0.name == "Security Expert" }) {
                return .security
            } else if participants.contains(where: { $0.name == "Strategist" }) {
                return .business
            } else {
                return .general
            }
        }
    }
}

// MARK: - TemplateCategory
enum TemplateCategory: String, CaseIterable {
    case development = "Sviluppo"
    case business = "Business"
    case creative = "Creativo"
    case security = "Sicurezza"
    case general = "Generale"
    
    var icon: String {
        switch self {
        case .development:
            return "⚙️"
        case .business:
            return "📈"
        case .creative:
            return "🎨"
        case .security:
            return "🛡️"
        case .general:
            return "👥"
        }
    }
    
    var description: String {
        switch self {
        case .development:
            return "Team per sviluppo prodotto e tecnologia"
        case .business:
            return "Team per analisi business e strategia"
        case .creative:
            return "Team per creatività e innovazione"
        case .security:
            return "Team per sicurezza e compliance"
        case .general:
            return "Team generici e personalizzabili"
        }
    }
    
    func getTemplates() -> [AgentGroupTemplate] {
        return AgentGroupTemplate.allTemplates.filter { $0.category == self }
    }
}

// MARK: - Template Builder
class AgentGroupTemplateBuilder {
    private var name: String = ""
    private var description: String = ""
    private var icon: String = "👥"
    private var participants: [GroupAgent] = []
    private var agentType: AgentType = .agentGroup
    private var useCases: [String] = []
    
    func setName(_ name: String) -> AgentGroupTemplateBuilder {
        self.name = name
        return self
    }
    
    func setDescription(_ description: String) -> AgentGroupTemplateBuilder {
        self.description = description
        return self
    }
    
    func setIcon(_ icon: String) -> AgentGroupTemplateBuilder {
        self.icon = icon
        return self
    }
    
    func addParticipant(_ agent: GroupAgent) -> AgentGroupTemplateBuilder {
        if !participants.contains(where: { $0.id == agent.id }) {
            participants.append(agent)
        }
        return self
    }
    
    func addParticipants(_ agents: [GroupAgent]) -> AgentGroupTemplateBuilder {
        for agent in agents {
            addParticipant(agent)
        }
        return self
    }
    
    func setAgentType(_ type: AgentType) -> AgentGroupTemplateBuilder {
        self.agentType = type
        return self
    }
    
    func addUseCase(_ useCase: String) -> AgentGroupTemplateBuilder {
        if !useCases.contains(useCase) {
            useCases.append(useCase)
        }
        return self
    }
    
    func build() -> AgentGroupTemplate {
        return AgentGroupTemplate(
            name: name.isEmpty ? "Custom Group" : name,
            description: description.isEmpty ? "Gruppo personalizzato" : description,
            icon: icon,
            participants: participants.isEmpty ? [.dataAnalyst] : participants,
            agentType: agentType,
            useCases: useCases
        )
    }
}