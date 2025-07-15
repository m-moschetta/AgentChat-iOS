import Foundation

struct Assistant: Identifiable, Hashable {
    let id: String
    let name: String
}

// Modelli per parsing JSON sicuro
struct ThreadResponse: Codable {
    let id: String
}

struct MessageResponse: Codable {
    let id: String
}

struct RunResponse: Codable {
    let id: String
    let status: String
}

struct MessagesListResponse: Codable {
    let data: [MessageData]
}

struct MessageData: Codable {
    let id: String
    let role: String
    let content: [ContentBlock]
    let runId: String?

    private enum CodingKeys: String, CodingKey {
        case id, role, content
        case runId = "run_id"
    }
}

struct ContentBlock: Codable {
    let type: String
    let text: TextContent?
}

struct TextContent: Codable {
    let value: String
}

// Client per OpenAI Assistants API (thread-based)
@MainActor
class OpenAIAssistantService {
    static let shared = OpenAIAssistantService()
    
    static let availableAssistants: [Assistant] = [
        Assistant(id: "asst_J1Mn3qvYUgFlBdhsZsGDrma9", name: "Assistente Generale"),
        Assistant(id: "ID_SECONDO_ASSISTENTE", name: "Esperto di Codice Swift")
    ]
    
    private var apiKey: String {
        return KeychainService.shared.getAPIKey(for: "openai") ?? ""
    }
    private var threadIds: [UUID: String] = [:] // Associa chat locali a thread OpenAI
    
    // Crea nuovo thread o usa esistente, invia messaggio, ritorna risposta
    func sendMessage(userMessage: String, forChat chatId: UUID, withAssistantId assistantId: String) async throws -> String {
        let threadId = try await getOrCreateThread(for: chatId)
        let messageId = try await postMessage(threadId: threadId, content: userMessage)
        let runId = try await createRun(threadId: threadId, assistantId: assistantId)
        let response = try await pollForResponse(threadId: threadId, runId: runId, userMessageId: messageId)
        return response
    }
    
    private func getOrCreateThread(for chatId: UUID) async throws -> String {
        if let tid = threadIds[chatId] { return tid }
        
        let url = URL(string: "https://api.openai.com/v1/threads")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("assistants=v2", forHTTPHeaderField: "OpenAI-Beta") // Header importante per API v2
        
        request.httpBody = try JSONSerialization.data(withJSONObject: [:])
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Controllo errori HTTP
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            let errorBody = String(data: data, encoding: .utf8) ?? "No response body"
            throw NSError(domain: "OpenAIAssistantService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Thread creation failed: \(errorBody)"])
        }
        
        // Debug print response data
        print("THREAD RESPONSE: \(String(decoding: data, as: UTF8.self))")
        
        do {
            let threadResponse = try JSONDecoder().decode(ThreadResponse.self, from: data)
            threadIds[chatId] = threadResponse.id
            return threadResponse.id
        } catch {
            print("Decoding ThreadResponse failed:", error)
            throw error
        }
    }
    
    private func postMessage(threadId: String, content: String) async throws -> String {
        let url = URL(string: "https://api.openai.com/v1/threads/\(threadId)/messages")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("assistants=v2", forHTTPHeaderField: "OpenAI-Beta")
        
        let body: [String: Any] = ["role": "user", "content": content]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            let errorBody = String(data: data, encoding: .utf8) ?? "No response body"
            throw NSError(domain: "OpenAIAssistantService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Message creation failed: \(errorBody)"])
        }
        
        // Debug print response data
        print("MESSAGE RESPONSE: \(String(decoding: data, as: UTF8.self))")
        
        do {
            let messageResponse = try JSONDecoder().decode(MessageResponse.self, from: data)
            return messageResponse.id
        } catch {
            print("Decoding MessageResponse failed:", error)
            throw error
        }
    }
    
    private func createRun(threadId: String, assistantId: String) async throws -> String {
        let url = URL(string: "https://api.openai.com/v1/threads/\(threadId)/runs")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("assistants=v2", forHTTPHeaderField: "OpenAI-Beta")
        
        let body: [String: Any] = ["assistant_id": assistantId]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            let errorBody = String(data: data, encoding: .utf8) ?? "No response body"
            throw NSError(domain: "OpenAIAssistantService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Run creation failed: \(errorBody)"])
        }
        
        // Debug print response data
        print("RUN RESPONSE: \(String(decoding: data, as: UTF8.self))")
        
        do {
            let runResponse = try JSONDecoder().decode(RunResponse.self, from: data)
            return runResponse.id
        } catch {
            print("Decoding RunResponse failed:", error)
            throw error
        }
    }

    private func pollForResponse(threadId: String, runId: String, userMessageId: String) async throws -> String {
        let statusUrl = URL(string: "https://api.openai.com/v1/threads/\(threadId)/runs/\(runId)")!
        let messagesUrl = URL(string: "https://api.openai.com/v1/threads/\(threadId)/messages")!
        
        for attempt in 0..<60 {
            do {
                // Verifica stato run
                var request = URLRequest(url: statusUrl)
                request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                request.setValue("assistants=v2", forHTTPHeaderField: "OpenAI-Beta")
                
                let (data, _) = try await URLSession.shared.data(for: request)
                
                do {
                    let runResponse = try JSONDecoder().decode(RunResponse.self, from: data)
                    
                    if runResponse.status == "completed" {
                        // Recupera messaggi
                        var messagesRequest = URLRequest(url: messagesUrl)
                        messagesRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                        messagesRequest.setValue("assistants=v2", forHTTPHeaderField: "OpenAI-Beta")
                        
                        let (messagesData, _) = try await URLSession.shared.data(for: messagesRequest)
                        
                        // Debug print messages data
                        print("MESSAGES RESPONSE: \(String(decoding: messagesData, as: UTF8.self))")
                        
                        do {
                            let messagesResponse = try JSONDecoder().decode(MessagesListResponse.self, from: messagesData)
                            
                            if let assistantMessage = messagesResponse.data.first(where: { $0.role == "assistant" && $0.runId == runId }) {
                                if let textContent = assistantMessage.content.first(where: { $0.type == "text" })?.text {
                                    return textContent.value
                                }
                            }
                        } catch {
                            print("Decoding MessagesListResponse failed:", error)
                            throw error
                        }
                    } else if runResponse.status == "failed" || runResponse.status == "cancelled" {
                        throw NSError(domain: "OpenAIAssistantService", code: 5, userInfo: [NSLocalizedDescriptionKey: "Run failed with status: \(runResponse.status)"])
                    }
                } catch {
                    print("Decoding RunResponse failed in pollForResponse:", error)
                    throw error
                }
                
                // Backoff esponenziale per ridurre carico API
                let delay = min(1.0 * pow(1.2, Double(attempt)), 5.0)
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                
            } catch {
                if attempt == 59 { throw error }
                try await Task.sleep(nanoseconds: 1_000_000_000)
            }
        }
        throw NSError(domain: "OpenAIAssistantService", code: 6, userInfo: [NSLocalizedDescriptionKey: "Polling timeout"])
    }
}

