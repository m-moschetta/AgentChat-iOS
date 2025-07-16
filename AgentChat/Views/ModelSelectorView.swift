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
        NavigationView {
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
        // OpenAI - Modelli più recenti (Luglio 2025)
        case let m where m.contains("o3-pro"):
            return "Versione premium di o3 con pensiero esteso (2025)"
        case let m where m.contains("o3") && !m.contains("mini"):
            return "Modello di ragionamento più avanzato di OpenAI (2025)"
        case let m where m.contains("o4-mini-high"):
            return "Versione potenziata di o4-mini per compiti visivi (2025)"
        case let m where m.contains("o4-mini"):
            return "Modello di ragionamento veloce e ottimizzato (2025)"
        case let m where m.contains("gpt-4.1") && m.contains("nano"):
            return "Modello ultra-veloce per classificazione e autocompletamento"
        case let m where m.contains("gpt-4.1") && m.contains("mini"):
            return "Modello piccolo con prestazioni eccezionali"
        case let m where m.contains("gpt-4.1"):
            return "Modello flagship per compiti complessi con coding avanzato (2025)"
        case let m where m.contains("gpt-4.5"):
            return "Modello sperimentale (deprecato dal 14 luglio 2025)"
        case let m where m.contains("gpt-4o-mini"):
            return "Versione più veloce ed economica di GPT-4o"
        case let m where m.contains("gpt-4o"):
            return "Modello multimodale avanzato (sostituisce GPT-4 Turbo)"
        case let m where m.contains("gpt-3.5-turbo"):
            return "Modello legacy (supportato fino a fine luglio 2025)"
        case let m where m.contains("text-embedding"):
            return "Modello per embedding semantici"
        case let m where m.contains("gpt-image"):
            return "Modello per generazione immagini"
            
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
        case let m where m.contains("r1-1776"):
            return "Versione non censurata di DeepSeek R1"
            
        // Grok - Modelli più recenti (Luglio 2025)
        case let m where m.contains("grok-4-heavy"):
            return "Versione multi-agente per compiti complessi (2025)"
        case let m where m.contains("grok-4"):
            return "Modello flagship 'più intelligente al mondo' (2025)"
        case let m where m.contains("grok-3"):
            return "Modello precedente con ragionamento avanzato"
        case let m where m.contains("grok-beta"):
            return "Modello principale legacy"
        case let m where m.contains("grok-vision-beta"):
            return "Con capacità visive legacy"
            
        // DeepSeek - Modelli più recenti (Luglio 2025)
        case let m where m.contains("deepseek-r1-0528"):
            return "Versione aggiornata con migliori capacità di ragionamento (2025)"
        case let m where m.contains("deepseek-r1-distill-70b"):
            return "Versione distillata 70B del modello R1"
        case let m where m.contains("deepseek-r1-distill-32b"):
            return "Versione distillata 32B del modello R1"
        case let m where m.contains("deepseek-r1"):
            return "Modello di ragionamento originale"
        case let m where m.contains("deepseek-v3-0324"):
            return "Versione aggiornata con prestazioni migliorate (2025)"
        case let m where m.contains("deepseek-v3"):
            return "Modello base con 671B parametri"
        case let m where m.contains("deepseek-coder-v2"):
            return "Specializzato per coding avanzato"
        case let m where m.contains("deepseek-math"):
            return "Specializzato per matematica"
            
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
        selectedModel: "gpt-4o"
    )
    
    ModelSelectorView(chat: sampleChat)
}