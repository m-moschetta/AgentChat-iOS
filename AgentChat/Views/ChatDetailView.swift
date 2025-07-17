//
//  ChatDetailView.swift
//  AgentChat
//
//  Created by Mario Moschetta on 04/07/25.
//

import SwiftUI

// MARK: - ChatDetailView
struct ChatDetailView: View {
    public init(chat: Binding<Chat>) {
        self._chat = chat
    }
    @Binding var chat: Chat
    @Environment(\.dismiss) private var dismiss
    @State private var inputText = ""
    @State private var textEditorHeight: CGFloat = 30
    @FocusState private var isInputFocused: Bool
    @State private var isAwaitingAssistant = false
    @State private var errorMessage: String?
    @State private var showParameterSheet = false
    @State private var showModelSelector = false
    @State private var showAgentConfig = false
    @State private var workflowParameters: [String: String] = [:]

    private var agentConfigManager = AgentConfigurationManager.shared
    private var chatManager = ChatManager.shared

    var body: some View {
        chatContent
             .toolbar {
                 ToolbarItem(placement: .principal) {
                     titleView
                 }
                 
                 ToolbarItem(placement: .primaryAction) {
                     HStack {
                         if chat.agentConfiguration != nil {
                             Button {
                                 showAgentConfig = true
                             } label: {
                                 Image(systemName: "person.crop.circle.badge.plus")
                             }
                         }
                         
                         if chat.n8nWorkflow == nil {
                             Button {
                                 showModelSelector = true
                             } label: {
                                 Image(systemName: "cpu")
                             }
                         }
                         
                         if let workflow = chat.n8nWorkflow, !workflow.parameters.isEmpty {
                             Button {
                                 showParameterSheet = true
                             } label: {
                                 Image(systemName: "slider.horizontal.3")
                             }
                         }
                     }
                 }
             }
            .onAppear {
                isInputFocused = true
            }
            .sheet(isPresented: $showParameterSheet) {
                WorkflowParameterSheet(
                    workflow: chat.n8nWorkflow!,
                    parameters: $workflowParameters
                )
            }
            .sheet(isPresented: $showModelSelector) {
                ModelSelectorView(chat: $chat)
            }
            .sheet(isPresented: $showAgentConfig) {
                if let agentConfig = chat.agentConfiguration {
                    AgentEditView(agent: agentConfig, onSave: { updatedAgent in
                        chat.agentConfiguration = updatedAgent
                        agentConfigManager.updateAgent(updatedAgent)
                    })
                } else {
                    AgentConfigurationView()
                }
            }
    }
    
    private var chatContent: some View {
        VStack(spacing: 0) {
            messagesList
            errorView
            Divider()
            inputSection
        }
    }
    
    private var messagesList: some View {
        ScrollViewReader { proxy in
            List(chat.messages) { message in
                messageRow(message)
    
            }
            .listStyle(.plain)
            .onAppear {
                scrollToLastMessage(proxy)
            }
            .onChange(of: chat.messages) { _, newValue in
                scrollToLastMessageAnimated(proxy, messages: newValue)
            }
        }
    }
    
    private func messageRow(_ message: Message) -> some View {
        HStack {
            if message.isUser {
                Spacer()
                Text(message.content)
                    .padding(10)
                    .background(Color.accentColor.opacity(0.2))
                    .cornerRadius(16)
                    .id(message.id)
            } else {
                Text(message.content)
                    .padding(10)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(16)
                    .id(message.id)
                Spacer()
            }
        }
        .listRowSeparator(.hidden)
    }
    
    @ViewBuilder
    private var errorView: some View {
        if let errorMessage {
            Text(errorMessage)
                .foregroundColor(.red)
                .padding(.horizontal)
        }
    }
    
    private var inputSection: some View {
        HStack {
            TextEditor(text: $inputText)
                .onChange(of: inputText) { _, _ in
                    updateTextEditorHeight()
                }
                .frame(height: textEditorHeight)
                .padding(4)
                .background(Color.white)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                )

                .focused($isInputFocused)

                .disabled(isAwaitingAssistant)
            
            sendButton
        }
        .padding(12)
        .background(.ultraThinMaterial)
    }
    
    private func updateTextEditorHeight() {
        let horizontalPadding: CGFloat = 24
        let buttonWidth: CGFloat = 40
        let availableWidth = UIScreen.main.bounds.width - horizontalPadding - buttonWidth
        let newHeight = min(150, max(30, inputText.heightForWidth(width: availableWidth, font: .systemFont(ofSize: 17))))
        if newHeight != textEditorHeight {
            textEditorHeight = newHeight
        }
    }

    private var sendButton: some View {
        Button {
            Task { await sendMessage() }
        } label: {
            if isAwaitingAssistant {
                ProgressView()
                    .scaleEffect(0.8)
            } else {
                Image(systemName: "paperplane.fill")
            }
        }
        .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isAwaitingAssistant)
        .padding(.leading, 4)
    }
    
    private var titleView: some View {
        VStack {
            HStack {
                if let workflow = chat.n8nWorkflow {
                    Text(workflow.icon)
                        .font(.caption)
                    Text(workflow.name)
                        .font(.headline)
                } else if let agentConfig = chat.agentConfiguration {
                    Text(agentConfig.icon)
                        .font(.caption)
                    Text(agentConfig.name)
                        .font(.headline)
                } else if let groupTemplate = chat.groupTemplate {
                    Text(groupTemplate.icon)
                        .font(.caption)
                    Text(groupTemplate.name)
                        .font(.headline)
                } else {
                    Text(chat.agentType.icon)
                        .font(.caption)
                    Text(chat.agentType.displayName)
                        .font(.headline)
                }
            }
            
            if let workflow = chat.n8nWorkflow {
                Text(workflow.category.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else if let agentConfig = chat.agentConfiguration {
                Text(agentConfig.role)
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else if let groupTemplate = chat.groupTemplate {
                Text(groupTemplate.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else if let model = chat.selectedModel {
                Text(model)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func scrollToLastMessage(_ proxy: ScrollViewProxy) {
        if let last = chat.messages.last {
            proxy.scrollTo(last.id, anchor: UnitPoint.bottom)
        }
    }
    
    private func scrollToLastMessageAnimated(_ proxy: ScrollViewProxy, messages: [Message]) {
        guard let last = messages.last else { return }
        DispatchQueue.main.async {
            withAnimation {
                proxy.scrollTo(last.id, anchor: UnitPoint.bottom)
            }
        }
    }
    
    // MARK: - Send Message
    func sendMessage() async {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isAwaitingAssistant else { return }
        
        let userMsg: Message
        do {
            userMsg = try Message(id: UUID(), content: trimmed, isUser: true, timestamp: Date())
        } catch {
            await MainActor.run {
                errorMessage = "Errore nella creazione del messaggio: \(error.localizedDescription)"
            }
            return
        }
        
        // SOLUZIONE: Elimina race condition - non mutare direttamente chat.messages
        do {
            try ChatManager.shared.addMessage(to: chat, message: userMsg)
        } catch {
            // Gestire l'errore gracefully
            await MainActor.run {
                errorMessage = "Errore nell'invio del messaggio: \(error.localizedDescription)"
            }
            return
        }
        
        await MainActor.run {
            inputText = ""
            errorMessage = nil
            isAwaitingAssistant = true
        }
        
        let placeholderId = UUID()
        let placeholderMsg: Message
        do {
            placeholderMsg = try Message(id: placeholderId, content: "...", isUser: false, timestamp: Date())
        } catch {
            await MainActor.run {
                errorMessage = "Errore nella creazione del placeholder: \(error.localizedDescription)"
                isAwaitingAssistant = false
            }
            return
        }
        
        // SOLUZIONE: Usa ChatManager invece di mutazione diretta
        do {
            try ChatManager.shared.addMessage(to: chat, message: placeholderMsg)
        } catch {
            await MainActor.run {
                errorMessage = "Errore nell'aggiunta del placeholder: \(error.localizedDescription)"
                isAwaitingAssistant = false
            }
            return
        }
        
        do {
            let response: String
            
            if let workflow = chat.n8nWorkflow {
                var parameters = workflowParameters
                parameters["userMessage"] = trimmed
                
                let n8nResponse = try await N8NService.shared.executeWorkflow(
                    workflow,
                    parameters: parameters,
                    chatId: chat.id.uuidString
                )
                response = n8nResponse.message ?? "Nessuna risposta dal workflow"
            } else if let agentConfig = chat.agentConfiguration {
                let contextualPrompt = chat.buildContextualPrompt(for: trimmed)
                response = try await sendMessageToConfigurableAgent(
                    message: trimmed,
                    agentConfig: agentConfig,
                    contextualPrompt: contextualPrompt
                )
            } else {
                let config = AgentConfiguration(
                    name: chat.agentType.displayName,
                    systemPrompt: "",
                    personality: "",
                    role: "",
                    icon: chat.agentType.icon,
                    preferredProvider: chat.agentType.rawValue,
                    model: chat.selectedModel
                )
                response = try await UniversalAssistantService.shared.sendMessage(
                    trimmed,
                    configuration: config
                )
            }
            
            // SOLUZIONE: Rimuovi placeholder tramite ChatManager
            await removePlaceholderMessage(placeholderId)
            
            let responseText: String
            if chat.n8nWorkflow != nil {
                responseText = formatN8NResponse(response)
            } else {
                responseText = response
            }
            
            let assistantMessage: Message
            do {
                assistantMessage = try Message(id: UUID(), content: responseText, isUser: false, timestamp: Date())
            } catch {
                await MainActor.run {
                    errorMessage = "Errore nella creazione della risposta: \(error.localizedDescription)"
                }
                return
            }

            do {
                try ChatManager.shared.addMessage(to: chat, message: assistantMessage)
            } catch {
                await MainActor.run {
                    errorMessage = "Errore nel salvare la risposta: \(error.localizedDescription)"
                }
            }
            
        } catch {
            // SOLUZIONE: Rimuovi placeholder tramite ChatManager anche in caso di errore
            await removePlaceholderMessage(placeholderId)
            
            if let n8nError = error as? N8NError {
                switch n8nError {
                case .invalidURL: errorMessage = "URL endpoint non valido."
                case .missingRequiredParameter(let param): errorMessage = "Parametro obbligatorio mancante: \(param)"
                case .authenticationRequired: errorMessage = "Autenticazione richiesta per questo workflow."
                case .networkError(let error): errorMessage = "Errore di rete: \(error.localizedDescription)"
                case .invalidResponse: errorMessage = "Risposta non valida dal workflow."
                case .workflowNotFound: errorMessage = "Workflow non trovato."
                case .serverError(let message): errorMessage = "Errore del server: \(message)"
                }
            } else if let assistantError = error as? UniversalAssistantError {
                switch assistantError {
                case .unsupportedProvider: errorMessage = "Provider non supportato."
                case .configurationError(let message): errorMessage = "Errore di configurazione: \(message)"
                case .serviceError(let chatError): errorMessage = chatError.localizedDescription
                }
            } else if let chatError = error as? ChatServiceError {
                switch chatError {
                case .missingAPIKey(let message): errorMessage = "API Key mancante: \(message)"
                case .invalidConfiguration: errorMessage = "Configurazione non valida."
                case .unsupportedModel(let model): errorMessage = "Modello non supportato: \(model)"
                case .invalidResponse: errorMessage = "Risposta non valida dal provider."
                case .authenticationFailed: errorMessage = "Autenticazione fallita. Verifica le credenziali."
                case .rateLimitExceeded: errorMessage = "Limite di richieste superato. Riprova più tardi."
                case .serverError(let message): errorMessage = "Errore del server: \(message)"
                case .networkError(let error): errorMessage = "Errore di rete: \(error.localizedDescription)"
                case .invalidSessionId: errorMessage = "ID sessione non valido."
                case .configurationNotFound: errorMessage = "Configurazione dell'agente non trovata."
                case .invalidMessage(let message): errorMessage = "Messaggio non valido: \(message)"
                case .invalidChat(let message): errorMessage = "Chat non valida: \(message)"
                case .chatNotFound(let message): errorMessage = "Chat non trovata: \(message)"
                }
            } else {
                errorMessage = "Errore: \(error.localizedDescription)"
            }
        }
        
        await MainActor.run {
            isAwaitingAssistant = false
        }
    }
    
    // MARK: - Helper Methods
    @MainActor
    private func removePlaceholderMessage(_ placeholderId: UUID) async {
        // SOLUZIONE: Metodo thread-safe per rimuovere placeholder
        if let chatIndex = ChatManager.shared.chats.firstIndex(where: { $0.id == chat.id }),
           let messageIndex = ChatManager.shared.chats[chatIndex].messages.firstIndex(where: { $0.id == placeholderId }) {
            
            // Rimuovi il messaggio dall'array locale
            ChatManager.shared.chats[chatIndex].messages.remove(at: messageIndex)
            
            // Salva le modifiche tramite il metodo pubblico
            ChatManager.shared.saveChat(ChatManager.shared.chats[chatIndex])
        }
    }
    
    // MARK: - Configurable Agent Message
    private func sendMessageToConfigurableAgent(
        message: String,
        agentConfig: AgentConfiguration,
        contextualPrompt: String
    ) async throws -> String {
        let providerName = agentConfig.preferredProvider
        guard let provider = AssistantProvider.defaultProviders.first(where: { $0.name == providerName }) ?? AssistantProvider.defaultProviders.first else {
            throw ChatServiceError.unsupportedModel("Provider non trovato: \(providerName)")
        }
        
        let fullMessage = "\(contextualPrompt)\n\nUser: \(message)"
        
        let agentType: AgentType = {
            switch provider.type {
            case .openai: return .openAI
            case .anthropic: return .claude
            case .mistral: return .mistral
            case .perplexity: return .perplexity
            case .grok: return .grok
            case .deepSeek: return .deepSeek
            case .n8n: return .n8n
            case .custom: return .custom
            }
        }()
        
        guard let service = chatManager.getChatService(for: agentType) else {
            throw ChatServiceError.unsupportedModel("Servizio non disponibile per \(agentType.displayName)")
        }
        
        return try await service.sendMessage(
            fullMessage,
            configuration: agentConfig
        )
    }
    
    // MARK: - Format N8N Response
    private func formatN8NResponse(_ response: String) -> String {
        if let data = response.data(using: .utf8),
           let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            
            var formattedResponse = ""
            if let responseText = jsonObject["response"] as? String { formattedResponse += responseText }
            if let status = jsonObject["status"] as? String { formattedResponse += "\n\n📊 Status: \(status)" }
            if let actionRequired = jsonObject["actionRequired"] as? String { formattedResponse += "\n\n⚡ Azione richiesta: \(actionRequired)" }
            if let publishedUrl = jsonObject["publishedUrl"] as? String { formattedResponse += "\n\n🔗 URL pubblicato: \(publishedUrl)" }
            
            return formattedResponse.isEmpty ? response : formattedResponse
        }
        
        return response
    }
}

// MARK: - WorkflowParameterSheet
struct WorkflowParameterSheet: View {
    let workflow: N8NWorkflow
    @Binding var parameters: [String: String]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                workflowSection
                
                if !workflow.parameters.isEmpty {
                    parametersSection
                }
            }
            .navigationTitle("Configura Parametri")
            .toolbar {
                  ToolbarItem(placement: .cancellationAction) {
                      Button("Annulla") { dismiss() }
                  }
                  
                  ToolbarItem(placement: .confirmationAction) {
                      Button("Salva") { dismiss() }
                          .font(.system(size: 17, weight: .semibold))
                  }
              }
        }
    }
    
    private var workflowSection: some View {
        Section {
            HStack {
                Text(workflow.icon)
                    .font(.title2)
                VStack(alignment: .leading) {
                    Text(workflow.name)
                        .font(.headline)
                    Text(workflow.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding(.vertical, 4)
        } header: {
            Text("Workflow")
        }
    }
    
    private var parametersSection: some View {
        Section {
            ForEach(workflow.parameters, id: \.id) { parameter in
                parameterRow(parameter)
            }
        } header: {
            Text("Parametri")
        } footer: {
            Text("Configura i parametri per questo workflow. I campi contrassegnati con * sono obbligatori.")
        }
    }
    
    private func parameterRow(_ parameter: N8NParameter) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(parameter.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                if parameter.isRequired {
                    Text("*")
                        .foregroundColor(.red)
                }
                Spacer()
            }
            
            if !parameter.description.isEmpty {
                Text(parameter.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            parameterInput(parameter)
        }
        .padding(.vertical, 2)
    }
    
    @ViewBuilder
    private func parameterInput(_ parameter: N8NParameter) -> some View {
        switch parameter.type {
        case .text, .multiline:
            TextField(parameter.placeholder, text: Binding(
                get: { parameters[parameter.name] ?? "" },
                set: { parameters[parameter.name] = $0 }
            ))
            .textFieldStyle(.roundedBorder)
            
        case .number:
            TextField(parameter.placeholder, text: Binding(
                get: { parameters[parameter.name] ?? "" },
                set: { parameters[parameter.name] = $0 }
            ))
            .textFieldStyle(.roundedBorder)
            .keyboardType(.numberPad) // <-- Added keyboard type
            
        case .boolean:
            Toggle(isOn: Binding(
                get: { parameters[parameter.name] == "true" },
                set: { parameters[parameter.name] = $0 ? "true" : "false" }
            )) {
                Text(parameter.placeholder)
            }
            
        case .select:
            if let selectOptions = parameter.selectOptions, !selectOptions.isEmpty {
                Picker(parameter.placeholder, selection: Binding(
                    get: { parameters[parameter.name] ?? selectOptions.first ?? "" },
                    set: { parameters[parameter.name] = $0 }
                )) {
                    ForEach(selectOptions, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                .pickerStyle(.menu)
            }
         }
    }
}

// MARK: - Preview
#Preview {
    // Wrapper view to hold the state for the preview
    struct PreviewWrapper: View {
        @State private var sampleChat = Chat(
            messages: [
                Message.createUnsafe(content: "Ciao!", isUser: true),
                Message.createUnsafe(content: "Ciao! Come posso aiutarti oggi?", isUser: false)
            ],
            agentType: .openAI,
            memoryManager: AgentMemoryManager.shared
        )
        
        var body: some View {
            NavigationView {
                ChatDetailView(chat: $sampleChat)
            }
        }
    }
    
    return PreviewWrapper()
}