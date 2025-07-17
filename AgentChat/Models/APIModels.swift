//
//  APIModels.swift
//  AgentChat
//
//  Created by Agent on 2024-01-XX.
//

import Foundation

// MARK: - OpenAI API Models

struct OpenAIRequest: Codable {
    let model: String
    let messages: [OpenAIMessage]
    let temperature: Double?
    let maxTokens: Int?
    let topP: Double?
    let stream: Bool?
    let stop: [String]?
    let presencePenalty: Double?
    let frequencyPenalty: Double?
    
    init(model: String, messages: [OpenAIMessage], maxTokens: Int? = nil, temperature: Double? = nil, stream: Bool? = nil, topP: Double? = nil, stop: [String]? = nil, presencePenalty: Double? = nil, frequencyPenalty: Double? = nil) {
        self.model = model
        self.messages = messages
        self.maxTokens = maxTokens
        self.temperature = temperature
        self.stream = stream
        self.topP = topP
        self.stop = stop
        self.presencePenalty = presencePenalty
        self.frequencyPenalty = frequencyPenalty
    }
    
    enum CodingKeys: String, CodingKey {
        case model, messages, temperature, stream, stop
        case maxTokens = "max_tokens"
        case topP = "top_p"
        case presencePenalty = "presence_penalty"
        case frequencyPenalty = "frequency_penalty"
    }
}

struct OpenAIMessage: Codable {
    let role: String
    let content: String
    let name: String?
    
    init(role: String, content: String, name: String? = nil) {
        self.role = role
        self.content = content
        self.name = name
    }
}

struct OpenAIResponse: Codable {
    let id: String
    let object: String
    let created: Int
    let model: String
    let choices: [OpenAIChoice]
    let usage: OpenAIUsage?
}

struct OpenAIChoice: Codable {
    let index: Int
    let message: OpenAIMessage
    let finishReason: String?
    
    enum CodingKeys: String, CodingKey {
        case index, message
        case finishReason = "finish_reason"
    }
}

struct OpenAIUsage: Codable {
    let promptTokens: Int
    let completionTokens: Int
    let totalTokens: Int
    
    enum CodingKeys: String, CodingKey {
        case promptTokens = "prompt_tokens"
        case completionTokens = "completion_tokens"
        case totalTokens = "total_tokens"
    }
}

struct OpenAIErrorResponse: Codable {
    let error: OpenAIError
}

struct OpenAIError: Codable {
    let message: String
    let type: String?
    let code: String?
}

// MARK: - Anthropic API Models

struct AnthropicRequest: Codable {
    let model: String
    let messages: [AnthropicMessage]
    let maxTokens: Int
    let temperature: Double?
    let topP: Double?
    let topK: Int?
    let system: String?
    let stream: Bool?
    let stopSequences: [String]?
    
    enum CodingKeys: String, CodingKey {
        case model, messages, temperature, system, stream
        case maxTokens = "max_tokens"
        case topP = "top_p"
        case topK = "top_k"
        case stopSequences = "stop_sequences"
    }
}

struct AnthropicMessage: Codable {
    let role: String
    let content: String
    
    init(role: String, content: String) {
        self.role = role
        self.content = content
    }
}

struct AnthropicResponse: Codable {
    let id: String
    let type: String
    let role: String
    let model: String
    let content: [AnthropicContent]
    let usage: AnthropicUsage
    let stopReason: String?
    let stopSequence: String?
    
    enum CodingKeys: String, CodingKey {
        case id, type, role, model, content, usage
        case stopReason = "stop_reason"
        case stopSequence = "stop_sequence"
    }
}

struct AnthropicContent: Codable {
    let type: String
    let text: String?
}

struct AnthropicUsage: Codable {
    let inputTokens: Int
    let outputTokens: Int
    
    enum CodingKeys: String, CodingKey {
        case inputTokens = "input_tokens"
        case outputTokens = "output_tokens"
    }
}

// MARK: - Mistral API Models

struct MistralRequest: Codable {
    let model: String
    let messages: [MistralMessage]
    let temperature: Double?
    let maxTokens: Int?
    let topP: Double?
    let randomSeed: Int?
    let stream: Bool?
    let safePrompt: Bool?
    
    enum CodingKeys: String, CodingKey {
        case model, messages, temperature, stream
        case maxTokens = "max_tokens"
        case topP = "top_p"
        case randomSeed = "random_seed"
        case safePrompt = "safe_prompt"
    }
}

struct MistralMessage: Codable {
    let role: String
    let content: String
    
    init(role: String, content: String) {
        self.role = role
        self.content = content
    }
}

struct MistralResponse: Codable {
    let id: String
    let object: String
    let created: Int
    let model: String
    let choices: [MistralChoice]
    let usage: MistralUsage
}

struct MistralChoice: Codable {
    let index: Int
    let message: MistralMessage
    let finishReason: String?
    
    enum CodingKeys: String, CodingKey {
        case index, message
        case finishReason = "finish_reason"
    }
}

struct MistralUsage: Codable {
    let promptTokens: Int
    let completionTokens: Int
    let totalTokens: Int
    
    enum CodingKeys: String, CodingKey {
        case promptTokens = "prompt_tokens"
        case completionTokens = "completion_tokens"
        case totalTokens = "total_tokens"
    }
}

// MARK: - Grok API Models

struct GrokRequest: Codable {
    let model: String
    let messages: [GrokMessage]
    let temperature: Double?
    let maxTokens: Int?
    let topP: Double?
    let stream: Bool?
    let stop: [String]?
    
    enum CodingKeys: String, CodingKey {
        case model, messages, temperature, stream, stop
        case maxTokens = "max_tokens"
        case topP = "top_p"
    }
}

struct GrokMessage: Codable {
    let role: String
    let content: String
    
    init(role: String, content: String) {
        self.role = role
        self.content = content
    }
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

// MARK: - Perplexity API Models

struct PerplexityRequest: Codable {
    let model: String
    let messages: [PerplexityMessage]
    let maxTokens: Int?
    let temperature: Double?
    let topP: Double?
    let topK: Int?
    let stream: Bool?
    let presencePenalty: Double?
    let frequencyPenalty: Double?
    
    enum CodingKeys: String, CodingKey {
        case model, messages, temperature, stream
        case maxTokens = "max_tokens"
        case topP = "top_p"
        case topK = "top_k"
        case presencePenalty = "presence_penalty"
        case frequencyPenalty = "frequency_penalty"
    }
}

struct PerplexityMessage: Codable {
    let role: String
    let content: String
    
    init(role: String, content: String) {
        self.role = role
        self.content = content
    }
}

struct PerplexityResponse: Codable {
    let id: String
    let object: String
    let created: Int
    let model: String
    let choices: [PerplexityChoice]
    let usage: PerplexityUsage
}

struct PerplexityChoice: Codable {
    let index: Int
    let message: PerplexityMessage
    let finishReason: String?
    
    enum CodingKeys: String, CodingKey {
        case index, message
        case finishReason = "finish_reason"
    }
}

struct PerplexityUsage: Codable {
    let promptTokens: Int
    let completionTokens: Int
    let totalTokens: Int
    
    enum CodingKeys: String, CodingKey {
        case promptTokens = "prompt_tokens"
        case completionTokens = "completion_tokens"
        case totalTokens = "total_tokens"
    }
}