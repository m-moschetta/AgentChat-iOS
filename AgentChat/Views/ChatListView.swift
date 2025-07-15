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
    @StateObject private var chatService = ChatManager()
    @State private var selectedChat: Chat?
    @State private var showingNewChatSheet = false
    @State private var showingSettings = false
    @StateObject private var workflowManager = N8NWorkflowManager.shared
    
    var body: some View {
        NavigationSplitView {
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
                    
                    Button {
                        showingNewChatSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.title2)
                    }
                }
                .padding()
                
                // Chat List
                List(chatService.chats, selection: $selectedChat) { chat in
                    ChatRowView(chat: chat)
                        .tag(chat)
                }
                .listStyle(SidebarListStyle())
            }
            .navigationTitle("")
        } detail: {
            if let selectedChat = selectedChat {
                ChatDetailView(chat: selectedChat)
            } else {
                Text("Seleziona una chat per iniziare")
                    .foregroundColor(.secondary)
            }
        }
        .sheet(isPresented: $showingNewChatSheet) {
                NewChatView(workflowManager: workflowManager) { provider, model, workflow in
                    createNewChat(with: provider, model: model, workflow: workflow)
                    showingNewChatSheet = false
                }
            }
        .sheet(isPresented: $showingSettings) {
            SettingsView(workflowManager: workflowManager)
        }
        .onAppear {
            workflowManager.loadWorkflows()
        }
    }
    

    
    
    
    func createNewChat(with provider: AssistantProvider, model: String?, workflow: N8NWorkflow? = nil) {
        chatService.createNewChat(with: provider, model: model, workflow: workflow)
        selectedChat = chatService.chats.last
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
        case .n8n:
            return "gear.badge"
        case .custom:
            return "wrench.and.screwdriver"
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
        case .n8n:
            return "n8n"
        case .custom:
            return "Custom"
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

