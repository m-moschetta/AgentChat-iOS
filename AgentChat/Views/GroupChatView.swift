//
//  GroupChatView.swift
//  AgentChat
//
//  Created by Mario Moschetta on 04/07/25.
//

import SwiftUI

// MARK: - GroupChatView
struct GroupChatView: View {
    @ObservedObject var group: AgentGroup
    @State private var messageText = ""
    @State private var isConversationActive = false
    @State private var showingParticipants = false
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Header con informazioni del gruppo
            GroupHeaderView(
                group: group,
                showingParticipants: $showingParticipants
            )
            
            Divider()
            
            // Area messaggi
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(group.messages) { message in
                            GroupMessageBubble(message: message)
                                .id(message.id)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
                .onChange(of: group.messages.count) { _ in
                    // Auto-scroll all'ultimo messaggio
                    if let lastMessage = group.messages.last {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            Divider()
            
            // Input area
            GroupInputView(
                messageText: $messageText,
                isConversationActive: $isConversationActive,
                isTextFieldFocused: $isTextFieldFocused,
                onSend: { message in
                    Task {
                        await startGroupConversation(with: message)
                    }
                }
            )
        }
        .navigationTitle(group.name)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(action: {
                    showingParticipants.toggle()
                }) {
                    Image(systemName: "person.3.fill")
                        .foregroundColor(.blue)
                }
            }
        }
        .sheet(isPresented: $showingParticipants) {
            GroupParticipantsView(group: group)
        }
    }
    
    // MARK: - Private Methods
    private func startGroupConversation(with message: String) async {
        guard !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        isConversationActive = true
        messageText = ""
        isTextFieldFocused = false
        
        do {
            await group.startGroupConversation(with: message)
        } catch {
            // Gestione errori
            print("Errore nella conversazione di gruppo: \(error)")
        }
        
        isConversationActive = false
    }
}

// MARK: - GroupHeaderView
struct GroupHeaderView: View {
    let group: AgentGroup
    @Binding var showingParticipants: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                // Icona del gruppo
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [.blue.opacity(0.8), .purple.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 50, height: 50)
                    
                    Text(group.icon)
                        .font(.title2)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(group.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("\(group.participants.count) agenti attivi")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Status indicator
                HStack(spacing: 4) {
                    Circle()
                        .fill(group.isActive ? .green : .gray)
                        .frame(width: 8, height: 8)
                    
                    Text(group.isActive ? "Attivo" : "Inattivo")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            // Descrizione del gruppo
            if !group.description.isEmpty {
                Text(group.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // Preview partecipanti
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(group.participants.prefix(5)) { agent in
                        AgentAvatarView(agent: agent, size: .small)
                    }
                    
                    if group.participants.count > 5 {
                        Button(action: {
                            showingParticipants = true
                        }) {
                            ZStack {
                                Circle()
                                    .fill(.gray.opacity(0.3))
                                    .frame(width: 32, height: 32)
                                
                                Text("+\(group.participants.count - 5)")
                                    .font(.caption2)
                                    .fontWeight(.medium)
                            }
                        }
                    }
                }
                .padding(.horizontal, 2)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }
}

// MARK: - GroupMessageBubble
struct GroupMessageBubble: View {
    let message: GroupMessage
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Avatar dell'agente
            if !message.isFromUser {
                if let agentName = message.agentName,
                   let agent = getAgent(named: agentName) {
                    AgentAvatarView(agent: agent, size: .medium)
                } else {
                    DefaultAvatarView(sender: message.sender)
                }
            } else {
                Spacer()
                    .frame(width: 40)
            }
            
            VStack(alignment: message.isFromUser ? .trailing : .leading, spacing: 4) {
                // Nome dell'agente
                if !message.isFromUser {
                    Text(message.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
                
                // Contenuto del messaggio
                Text(message.content)
                    .font(.body)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(message.isFromUser ? .blue : .gray.opacity(0.1))
                    )
                    .foregroundColor(message.isFromUser ? .white : .primary)
                
                // Timestamp
                Text(formatTimestamp(message.timestamp))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            // Spacer per messaggi utente
            if message.isFromUser {
                Spacer()
                    .frame(width: 40)
            }
        }
        .frame(maxWidth: .infinity, alignment: message.isFromUser ? .trailing : .leading)
    }
    
    private func getAgent(named name: String) -> GroupAgent? {
        return GroupAgent.allAgents.first { $0.name == name }
    }
    
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - AgentAvatarView
struct AgentAvatarView: View {
    let agent: GroupAgent
    let size: AvatarSize
    
    enum AvatarSize {
        case small, medium, large
        
        var dimension: CGFloat {
            switch self {
            case .small: return 32
            case .medium: return 40
            case .large: return 60
            }
        }
        
        var fontSize: Font {
            switch self {
            case .small: return .caption
            case .medium: return .body
            case .large: return .title2
            }
        }
    }
    
    var body: some View {
        ZStack {
            Circle()
                .fill(LinearGradient(
                    colors: gradientColors(for: agent.role),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: size.dimension, height: size.dimension)
            
            Text(agent.icon)
                .font(size.fontSize)
        }
    }
    
    private func gradientColors(for role: String) -> [Color] {
        switch role {
        case let r where r.contains("Analyst"):
            return [.blue.opacity(0.8), .cyan.opacity(0.8)]
        case let r where r.contains("Creative"):
            return [.purple.opacity(0.8), .pink.opacity(0.8)]
        case let r where r.contains("Tech"):
            return [.green.opacity(0.8), .mint.opacity(0.8)]
        case let r where r.contains("Strategist"):
            return [.orange.opacity(0.8), .yellow.opacity(0.8)]
        case let r where r.contains("Critic"):
            return [.red.opacity(0.8), .orange.opacity(0.8)]
        default:
            return [.gray.opacity(0.8), .secondary.opacity(0.8)]
        }
    }
}

// MARK: - DefaultAvatarView
struct DefaultAvatarView: View {
    let sender: GroupMessage.MessageSender
    
    var body: some View {
        ZStack {
            Circle()
                .fill(.gray.opacity(0.3))
                .frame(width: 40, height: 40)
            
            Image(systemName: iconName)
                .foregroundColor(.secondary)
        }
    }
    
    private var iconName: String {
        switch sender {
        case .user:
            return "person.fill"
        case .agent:
            return "brain.head.profile"
        case .system:
            return "gear"
        }
    }
}

// MARK: - GroupInputView
struct GroupInputView: View {
    @Binding var messageText: String
    @Binding var isConversationActive: Bool
    @FocusState.Binding var isTextFieldFocused: Bool
    let onSend: (String) -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Campo di input
            TextField("Avvia una discussione di gruppo...", text: $messageText)
                .textFieldStyle(.roundedBorder)
                .focused($isTextFieldFocused)
                .disabled(isConversationActive)
                .onSubmit {
                    sendMessage()
                }
            
            // Pulsante invio
            Button(action: sendMessage) {
                if isConversationActive {
                    ProgressView()
                        .scaleEffect(0.8)
                        .frame(width: 24, height: 24)
                } else {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundColor(canSend ? .blue : .gray)
                }
            }
            .disabled(!canSend || isConversationActive)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }
    
    private var canSend: Bool {
        !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func sendMessage() {
        guard canSend else { return }
        onSend(messageText)
    }
}

// MARK: - GroupParticipantsView
struct GroupParticipantsView: View {
    let group: AgentGroup
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section("Partecipanti (\(group.participants.count))") {
                    ForEach(group.participants) { agent in
                        ParticipantRowView(agent: agent)
                    }
                }
                
                Section("Informazioni Gruppo") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(group.description)
                            .font(.body)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Dettagli Gruppo")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Chiudi") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - ParticipantRowView
struct ParticipantRowView: View {
    let agent: GroupAgent
    
    var body: some View {
        HStack(spacing: 12) {
            AgentAvatarView(agent: agent, size: .medium)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(agent.name)
                    .font(.headline)
                
                Text(agent.role)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(agent.personality)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview
#Preview {
    NavigationView {
        GroupChatView(
            group: AgentGroup(
                name: "Product Team",
                description: "Team di sviluppo prodotto",
                icon: "👥",
                participants: [GroupAgent.dataAnalyst, GroupAgent.creativeDirector, GroupAgent.techLead],
                agentType: .group
            )
        )
    }
}