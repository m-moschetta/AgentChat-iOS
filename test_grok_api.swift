import Foundation

// Strutture per la richiesta Grok
struct GrokRequest: Codable {
    let model: String
    let messages: [GrokMessage]
    let temperature: Double?
    let maxTokens: Int?
    let topP: Double?
    let stream: Bool
    
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
        
        // Codifica condizionale per parametri opzionali
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

// Funzione di test per l'API Grok
func testGrokAPI() {
    // Configurazione della richiesta
    let request = GrokRequest(
        model: "grok-2-latest",
        messages: [
            GrokMessage(role: "user", content: "Ciao! Come stai?")
        ],
        temperature: nil,
        maxTokens: nil,
        topP: nil,
        stream: false
    )
    
    // URL dell'endpoint Grok
    guard let url = URL(string: "https://api.x.ai/v1/chat/completions") else {
        print("URL non valido")
        return
    }
    
    // Configurazione della richiesta HTTP
    var urlRequest = URLRequest(url: url)
    urlRequest.httpMethod = "POST"
    urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
    urlRequest.setValue("Bearer YOUR_API_KEY_HERE", forHTTPHeaderField: "Authorization")
    
    // Codifica del corpo della richiesta
    do {
        let jsonData = try JSONEncoder().encode(request)
        urlRequest.httpBody = jsonData
        
        // Stampa il JSON per debug
        if let jsonString = String(data: jsonData, encoding: .utf8) {
            print("JSON della richiesta:")
            print(jsonString)
        }
        
        // Invio della richiesta
        let task = URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            if let error = error {
                print("Errore: \(error.localizedDescription)")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("Codice di stato: \(httpResponse.statusCode)")
            }
            
            if let data = data {
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Risposta del server:")
                    print(responseString)
                }
            }
        }
        
        task.resume()
        
    } catch {
        print("Errore nella codifica JSON: \(error)")
    }
}

// Esecuzione del test
print("Test dell'API Grok...")
testGrokAPI()

// Mantieni il programma in esecuzione per permettere alla richiesta di completarsi
RunLoop.main.run()