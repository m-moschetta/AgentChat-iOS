//
//  ModelSelectorView.swift
//  AgentChat
//
//  Created by Mario Moschetta on 04/07/25.
//

import SwiftUI

// MARK: - Model Selector View
struct ModelSelectorView: View {
    @ObservedObject var chat: Chat
    @Environment(\.dismiss) private var dismiss
    @StateObject private var config = LocalAssistantConfiguration()
    
    private var availableModels: [String] {
        guard let provider = chat.provider else { return [] }
        return provider.supportedModels
    }
    
    private var currentModel: String {
        return chat.selectedModel ?? chat.provider?.defaultModel ?? "Nessun modello"
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            if let provider = chat.provider {
                                Image(systemName: provider.icon)
                                    .foregroundColor(.accentColor)
                                    .frame(width: 24)
                                Text(provider.name)
                                    .font(.headline)
                            }
                        }
                        
                        Text("Modello attuale: \(currentModel)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Provider")
                }
                
                if !availableModels.isEmpty {
                    Section {
                        ForEach(availableModels, id: \.self) { model in
                            ModelRow(
                                model: model,
                                isSelected: model == currentModel,
                                onSelect: {
                                    chat.selectedModel = model
                                    dismiss()
                                }
                            )
                        }
                    } header: {
                        Text("Modelli Disponibili")
                    } footer: {
                        Text("Seleziona un modello per questa conversazione. Il cambiamento avrà effetto sui prossimi messaggi.")
                    }
                } else {
                    Section {
                        VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.largeTitle)
                                .foregroundColor(.orange)
                            
                            Text("Nessun modello disponibile")
                                .font(.headline)
                            
                            Text("Il provider selezionato non ha modelli configurati")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 32)
                    }
                }
            }
            .navigationTitle("Seleziona Modello")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Chiudi") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Model Row
struct ModelRow: View {
    let model: String
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(model)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(modelDescription(for: model))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentColor)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
    
    private func modelDescription(for model: String) -> String {
        // Descrizioni dei modelli basate sul nome
        switch model.lowercased() {
        // OpenAI - Modelli più recenti
        case let m where m.contains("o3") && !m.contains("mini"):
            return "Modello di ragionamento più avanzato di OpenAI (2025)"
        case let m where m.contains("o4-mini"):
            return "Modello di ragionamento veloce e ottimizzato (2025)"
        case let m where m.contains("gpt-4.1") && m.contains("nano"):
            return "Modello ultra-veloce per classificazione e autocompletamento"
        case let m where m.contains("gpt-4.1") && m.contains("mini"):
            return "Modello piccolo con prestazioni eccezionali"
        case let m where m.contains("gpt-4.1"):
            return "Modello specializzato per coding e istruzioni precise (2025)"
        case let m where m.contains("gpt-4o"):
            return "Modello multimodale flagship di OpenAI"
        case let m where m.contains("o1-mini"):
            return "Modello di ragionamento veloce ed efficiente"
        case let m where m.contains("o1"):
            return "Modello di ragionamento per problemi complessi"
            
        // Anthropic - Modelli più recenti
        case let m where m.contains("claude-opus-4"):
            return "Modello più capace e intelligente di Anthropic (2025)"
        case let m where m.contains("claude-sonnet-4"):
            return "Modello ad alte prestazioni con ragionamento eccezionale (2025)"
        case let m where m.contains("claude-3-7-sonnet"):
            return "Modello con ragionamento esteso e finestra di contesto 1M"
        case let m where m.contains("claude-3-5-sonnet"):
            return "Modello bilanciato con capacità di computer use"
        case let m where m.contains("claude-3-5-haiku"):
            return "Modello velocissimo che supera Claude 3 Opus"
        case let m where m.contains("claude-3-opus"):
            return "Modello legacy di Claude 3 (deprecato)"
        case let m where m.contains("claude-3-haiku"):
            return "Modello legacy veloce (deprecato)"
            
        // Mistral
        case let m where m.contains("large"):
            return "Modello grande e potente"
        case let m where m.contains("medium"):
            return "Bilanciato tra prestazioni e velocità"
        case let m where m.contains("small"):
            return "Modello veloce e leggero"
        case let m where m.contains("codestral"):
            return "Specializzato per la programmazione"
        case let m where m.contains("pixtral"):
            return "Modello multimodale con visione"
            
        // Perplexity - Modelli più recenti (2025)
        case let m where m.contains("sonar-reasoning-pro"):
            return "Modello di ragionamento premium con ricerca web avanzata"
        case let m where m.contains("sonar-reasoning"):
            return "Modello di ragionamento con capacità di ricerca"
        case let m where m.contains("sonar-deep-research"):
            return "Ricerca approfondita e sintesi di report esperti"
        case let m where m.contains("sonar-pro"):
            return "Modello premium con ricerca web e citazioni multiple"
        case let m where m.contains("sonar-large"):
            return "Modello Sonar ottimizzato per Perplexity (basato su Llama 3.3)"
        case let m where m.contains("sonar"):
            return "Modello veloce con capacità di ricerca web"
            
        default:
            return "Modello AI avanzato"
        }
    }
}

// MARK: - Preview
#Preview {
    let sampleChat = Chat(
        agentType: .openAI,
        provider: AssistantProvider.defaultProviders.first(where: { $0.type == .openai }),
        selectedModel: "gpt-4o",
        agents: [Agent(provider: AssistantProvider.defaultProviders.first(where: { $0.type == .openai })!, model: "gpt-4o")]
    )
    
    ModelSelectorView(chat: sampleChat)
}