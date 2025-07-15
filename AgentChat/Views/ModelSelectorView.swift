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
        // OpenAI
        case let m where m.contains("gpt-4o"):
            return "Modello multimodale avanzato di OpenAI"
        case let m where m.contains("o1"):
            return "Modello di ragionamento avanzato"
        case let m where m.contains("gpt-3.5"):
            return "Modello veloce ed efficiente"
            
        // Anthropic
        case let m where m.contains("claude-4"):
            return "Ultima generazione di Claude"
        case let m where m.contains("claude-3-5-sonnet"):
            return "Bilanciato tra velocità e capacità"
        case let m where m.contains("claude-3-opus"):
            return "Modello più potente di Claude 3"
        case let m where m.contains("claude-3-haiku"):
            return "Modello veloce e leggero"
            
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
            
        // Perplexity
        case let m where m.contains("sonar-pro"):
            return "Modello premium con ricerca web"
        case let m where m.contains("sonar"):
            return "Modello con capacità di ricerca"
            
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