//
//  ContentView.swift
//  AgentChat
//
//  Created by Mario Moschetta on 04/07/25.
//

import SwiftUI
import Foundation

// MARK: - ChatListView
struct ChatListView: View {
    @StateObject private var chatService = ChatManager.shared
    @State private var selectedChat: Chat?
    @State private var showingNewChatSheet = false
    @State private var showingSettings = false
    @State private var showingGroupSelection = false
    @State private var showingAgentConfig = false
    @State private var activeGroupChat: AgentGroup?
    @StateObject private var workflowManager = N8NWorkflowManager.shared
    @StateObject private var agentConfigManager = AgentConfigurationManager.shared
    @State private var verticalPadding: Double = 0
    
    var body: some View {
        NavigationView {
            VStack {
                // Header
                HStack {
                    Text("AgentChat")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.title2)
                    }
                    
                    // Pulsante per configurazione agenti
                    Button {
                        showingAgentConfig = true
                    } label: {
                        Image(systemName: "person.crop.circle.badge.plus")
                            .font(.title2)
                    }
                    
                    // Pulsante per creare gruppo agenti
                    Button {
                        showingGroupSelection = true
                    } label: {
                        Image(systemName: "person.3.fill")
                            .font(.title2)
                    }
                    
                    Button {
                        showingNewChatSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.title2)
                    }
                }
                .padding()
                
                // Chat List
                List {
                    ForEach(chatService.chats) { chat in
                        HStack {
                            Circle()
                                .fill(Color.accentColor.opacity(0.2))
                                .frame(width: 40, height: 40)
                                .overlay {
                                    if let workflow = chat.n8nWorkflow {
                                        Text(workflow.icon)
                                            .font(.title3)
                                    } else if chat.agentConfiguration != nil {
                                        Image(systemName: "person.crop.circle")
                                            .font(.title3)
                                            .foregroundColor(.purple)
                                    } else {
                                        Image(systemName: ChatListView.getAgentTypeIcon(chat.agentType))
                                            .font(.title3)
                                            .foregroundColor(.accentColor)
                                    }
                                }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    if let workflow = chat.n8nWorkflow {
                                        Text(workflow.name)
                                            .font(.headline)
                                            .lineLimit(1)
                                        Text(workflow.category.displayName)
                                            .font(.caption2)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.blue.opacity(0.2))
                                            .foregroundColor(.blue)
                                            .cornerRadius(4)
                                    } else if let agentConfig = chat.agentConfiguration {
                                        Text(agentConfig.name)
                                            .font(.headline)
                                            .lineLimit(1)
                                        Text(agentConfig.role)
                                            .font(.caption2)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.purple.opacity(0.2))
                                            .foregroundColor(.purple)
                                            .cornerRadius(4)
                                    } else {
                                        Text(ChatListView.getAgentTypeName(chat.agentType))
                                            .font(.headline)
                                            .lineLimit(1)
                                        
                                        if let model = chat.selectedModel {
                                            Text(model)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color.gray.opacity(0.2))
                                                .cornerRadius(4)
                                        }
                                    }
                                }
                                
                                if let lastMessage = chat.lastMessage {
                                    Text(lastMessage.content)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .lineLimit(2)
                                } else {
                                    Text("Nuova conversazione")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .italic()
                                }
                            }
                            
                            Spacer()
                            
                            VStack {
                                if let lastMessage = chat.lastMessage {
                                    Text(lastMessage.timestamp, style: .time)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                            }
                        }
                        .padding(.vertical, 8)
                        .background(
                            NavigationLink(
                                destination: ChatDetailView(chat: chat),
                                label: { EmptyView() }
                            )
                            .opacity(0)
                        )
                        .onTapGesture {
                            selectedChat = chat
                            activeGroupChat = nil
                        }
                    }
                    .onDelete(perform: deleteChats)
                }
                .listStyle(SidebarListStyle())
            }
            .navigationTitle("")
            
            // Vista principale quando nessuna chat è selezionata
            if selectedChat == nil {
                VStack(spacing: 20) {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    
                    VStack(spacing: 8) {
                        Text("Benvenuto in AgentChat")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Seleziona una chat o crea un gruppo di agenti per iniziare")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    HStack(spacing: 16) {
                        Button(action: {
                            showingNewChatSheet = true
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Nuova Chat")
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                        
                        Button(action: {
                            showingGroupSelection = true
                        }) {
                            HStack {
                                Image(systemName: "person.3.fill")
                                Text("Gruppo Agenti")
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(.purple)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                    }
                }
                .padding()
            }
        }
        .navigationViewStyle(.stack)
        .padding(.vertical, verticalPadding)
        .onAppear {
            let systemVersion = UIDevice.current.systemVersion
            if systemVersion.contains("18.") {
                // Aggiorna padding verticale per iOS 18
                verticalPadding = 0.5
            }
        }
        .sheet(isPresented: $showingNewChatSheet) {
                NewChatView(
                    workflowManager: workflowManager,
                    onChatCreated: { provider, model, workflow in
                        createNewChat(with: provider, model: model, workflow: workflow)
                        showingNewChatSheet = false
                    },
                    onAgentChatCreated: { agentConfig in
                        createNewChatWithAgent(agentConfig)
                        showingNewChatSheet = false
                    }
                )
            }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showingAgentConfig) {
            AgentConfigurationView()
        }
        .sheet(isPresented: $showingGroupSelection) {
            GroupSelectionView { template in
                createGroupChat(from: template)
            }
        }
        // Rimossa gestione sheet per activeGroupChat - ora i gruppi sono chat normali
        .onAppear {
            workflowManager.loadWorkflows()
        }
    }
    

    
    
    
    func createNewChat(with provider: AssistantProvider, model: String?, workflow: N8NWorkflow? = nil) {
        chatService.createNewChat(with: provider, model: model, workflow: workflow)
        selectedChat = chatService.chats.last
        activeGroupChat = nil // Deseleziona gruppo attivo
    }
    
    func createNewChatWithAgent(_ agentConfig: AgentConfiguration) {
        let newChat = Chat(
            agentConfiguration: agentConfig,
            chatType: .single,
            title: agentConfig.name
        )
        chatService.chats.append(newChat)
        selectedChat = newChat
        activeGroupChat = nil
    }
    
    func createGroupChat(from template: AgentGroupTemplate) {
        let newChat = Chat(
            agentType: .group,
            chatType: .group,
            title: template.name,
            groupTemplate: template
        )
        chatService.chats.append(newChat)
        selectedChat = newChat
        activeGroupChat = nil
    }
    
    func deleteChats(at offsets: IndexSet) {
        chatService.deleteChat(at: offsets)
        // Deseleziona la chat se è stata cancellata
        if let selectedChat = selectedChat,
           let selectedIndex = chatService.chats.firstIndex(where: { $0.id == selectedChat.id }),
           offsets.contains(selectedIndex) {
            self.selectedChat = nil
        }
    }
    
    static func getAgentTypeIcon(_ agentType: AgentType) -> String {
        switch agentType {
        case .openAI:
            return "brain.head.profile"
        case .claude:
            return "sparkles"
        case .mistral:
            return "wind"
        case .perplexity:
            return "magnifyingglass.circle"
        case .grok:
            return "bolt.circle"
        case .deepSeek:
            return "brain.head.profile"
        case .n8n:
            return "gear.badge"
        case .custom:
            return "wrench.and.screwdriver"
        case .hybridMultiAgent:
            return "brain.head.profile.fill"
        case .agentGroup:
            return "person.3.fill"
        case .group:
            return "person.3"
        case .productTeam:
            return "briefcase.fill"
        case .brainstormingSquad:
            return "lightbulb.fill"
        case .codeReviewPanel:
            return "checkmark.seal.fill"
        }
    }
    
    static func getAgentTypeName(_ agentType: AgentType) -> String {
        switch agentType {
        case .openAI:
            return "OpenAI"
        case .claude:
            return "Claude"
        case .mistral:
            return "Mistral"
        case .perplexity:
            return "Perplexity"
        case .grok:
            return "Grok"
        case .deepSeek:
            return "DeepSeek"
        case .n8n:
            return "n8n"
        case .custom:
            return "Custom"
        case .hybridMultiAgent:
            return "Hybrid Multi-Agent"
        case .agentGroup:
            return "Agent Group"
        case .group:
            return "Group"
        case .productTeam:
            return "Product Team"
        case .brainstormingSquad:
            return "Brainstorming Squad"
        case .codeReviewPanel:
            return "Code Review Panel"
        }
    }
}

// MARK: - ChatRowView
struct ChatRowView: View {
    let chat: Chat
    
    var body: some View {
        HStack {
            Circle()
                .fill(Color.accentColor.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay {
                    if let workflow = chat.n8nWorkflow {
                        Text(workflow.icon)
                            .font(.title3)
                    } else if chat.agentConfiguration != nil {
                        Image(systemName: "person.crop.circle")
                            .font(.title3)
                            .foregroundColor(.purple)
                    } else {
                        Image(systemName: ChatListView.getAgentTypeIcon(chat.agentType))
                            .font(.title3)
                            .foregroundColor(.accentColor)
                    }
                }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    if let workflow = chat.n8nWorkflow {
                        Text(workflow.name)
                            .font(.headline)
                            .lineLimit(1)
                        Text(workflow.category.displayName)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.2))
                            .foregroundColor(.blue)
                            .cornerRadius(4)
                    } else if let agentConfig = chat.agentConfiguration {
                        Text(agentConfig.name)
                            .font(.headline)
                            .lineLimit(1)
                        Text(agentConfig.role)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.purple.opacity(0.2))
                            .foregroundColor(.purple)
                            .cornerRadius(4)
                    } else {
                        Text(ChatListView.getAgentTypeName(chat.agentType))
                            .font(.headline)
                            .lineLimit(1)
                        
                        if let model = chat.selectedModel {
                            Text(model)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(4)
                        }
                    }
                }
                
                if let lastMessage = chat.lastMessage {
                    Text(lastMessage.content)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                } else {
                    Text("Nuova conversazione")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .italic()
                }
            }
            
            Spacer()
            
            VStack {
                if let lastMessage = chat.lastMessage {
                    Text(lastMessage.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
        .padding(.vertical, 8)
    }
    

}

// MARK: - Preview
#Preview {
    ChatListView()
}

