#!/usr/bin/env swift

import Foundation

// Strutture per testare l'API Grok
struct GrokRequest: Codable {
    let model: String
    let messages: [GrokMessage]
    let temperature: Double?
    let maxTokens: Int?
    let topP: Double?
    let stream: Bool?
    
    enum CodingKeys: String, CodingKey {
        case model, messages, temperature, stream
        case maxTokens = "max_tokens"
        case topP = "top_p"
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(model, forKey: .model)
        try container.encode(messages, forKey: .messages)
        try container.encode(stream, forKey: .stream)
        
        if let temperature = temperature {
            try container.encode(temperature, forKey: .temperature)
        }
        if let maxTokens = maxTokens {
            try container.encode(maxTokens, forKey: .maxTokens)
        }
        if let topP = topP {
            try container.encode(topP, forKey: .topP)
        }
    }
}

struct GrokMessage: Codable {
    let role: String
    let content: String
}

struct GrokResponse: Codable {
    let id: String
    let object: String
    let created: Int
    let model: String
    let choices: [GrokChoice]
    let usage: GrokUsage
}

struct GrokChoice: Codable {
    let index: Int
    let message: GrokMessage
    let finishReason: String?
    
    enum CodingKeys: String, CodingKey {
        case index, message
        case finishReason = "finish_reason"
    }
}

struct GrokUsage: Codable {
    let promptTokens: Int
    let completionTokens: Int
    let totalTokens: Int
    
    enum CodingKeys: String, CodingKey {
        case promptTokens = "prompt_tokens"
        case completionTokens = "completion_tokens"
        case totalTokens = "total_tokens"
    }
}

// Funzione di test
func testGrokAPI() async {
    // Nota: Sostituisci "YOUR_API_KEY" con la tua chiave API reale
    let apiKey = "YOUR_API_KEY"
    
    let request = GrokRequest(
        model: "grok-4",
        messages: [GrokMessage(role: "user", content: "Ciao, come stai?")],
        temperature: nil,
        maxTokens: nil,
        topP: nil,
        stream: false
    )
    
    guard let url = URL(string: "https://api.x.ai/v1/chat/completions") else {
        print("❌ URL non valido")
        return
    }
    
    var urlRequest = URLRequest(url: url)
    urlRequest.httpMethod = "POST"
    urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
    urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
    
    do {
        let jsonData = try JSONEncoder().encode(request)
        urlRequest.httpBody = jsonData
        
        // Stampa il JSON della richiesta per debug
        if let jsonString = String(data: jsonData, encoding: .utf8) {
            print("📤 JSON della richiesta:")
            print(jsonString)
        }
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        if let httpResponse = response as? HTTPURLResponse {
            print("📊 Status Code: \(httpResponse.statusCode)")
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("📥 Risposta del server:")
                print(responseString)
            }
            
            if httpResponse.statusCode == 200 {
                let grokResponse = try JSONDecoder().decode(GrokResponse.self, from: data)
                print("✅ Test riuscito!")
                print("💬 Risposta: \(grokResponse.choices.first?.message.content ?? "Nessuna risposta")")
            } else {
                print("❌ Test fallito con status code \(httpResponse.statusCode)")
            }
        }
    } catch {
        print("❌ Errore: \(error)")
    }
}

// Esegui il test
Task {
    await testGrokAPI()
    exit(0)
}

// Mantieni il programma in esecuzione
RunLoop.main.run()