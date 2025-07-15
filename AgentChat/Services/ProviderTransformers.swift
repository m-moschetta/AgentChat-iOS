//
//  ProviderTransformers.swift
//  AgentChat
//
//  Created by Mario Moschetta on 04/07/25.
//

import Foundation

// Import necessario per ChatServiceError
// Nota: ChatServiceError è definito in Models/ChatServiceError.swift

// MARK: - OpenAI Transformer
struct OpenAIRequestTransformer: RequestTransformer {
    func transform(_ request: UnifiedChatRequest) throws -> Data {
        let openAIRequest = OpenAIRequest(
            model: request.model,
            messages: request.messages.compactMap { message in
                guard !message.content.isEmpty else { return nil }
                return OpenAIMessage(role: message.role, content: message.content)
            },
            maxTokens: request.parameters.maxTokens,
            temperature: request.parameters.temperature,
            stream: request.parameters.stream
        )
        
        return try JSONEncoder().encode(openAIRequest)
    }
}

struct OpenAIResponseParser: ResponseParser {
    func parse(_ data: Data) throws -> UnifiedChatResponse {
        let openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        
        guard let choice = openAIResponse.choices.first,
              !choice.message.content.isEmpty else {
            throw ChatServiceError.invalidResponse
        }
        
        let content = choice.message.content
        
        return UnifiedChatResponse(
            content: content,
            model: openAIResponse.model,
            usage: TokenUsage(
                promptTokens: openAIResponse.usage?.promptTokens ?? 0,
                completionTokens: openAIResponse.usage?.completionTokens ?? 0,
                totalTokens: openAIResponse.usage?.totalTokens ?? 0
            )
        )
    }
}

// MARK: - Anthropic Transformer
struct AnthropicRequestTransformer: RequestTransformer {
    func transform(_ request: UnifiedChatRequest) throws -> Data {
        let anthropicRequest = AnthropicRequest(
            model: request.model,
            messages: request.messages.compactMap { message in
                 guard !message.content.isEmpty else { return nil }
                 return AnthropicMessage(role: message.role, content: message.content)
             },
            maxTokens: request.parameters.maxTokens ?? 4000,
            temperature: request.parameters.temperature,
            system: nil
        )
        
        return try JSONEncoder().encode(anthropicRequest)
    }
}

struct AnthropicResponseParser: ResponseParser {
    func parse(_ data: Data) throws -> UnifiedChatResponse {
        let anthropicResponse = try JSONDecoder().decode(AnthropicResponse.self, from: data)
        
        guard let content = anthropicResponse.content.first?.text else {
            throw ChatServiceError.invalidResponse
        }
        
        return UnifiedChatResponse(
            content: content,
            model: anthropicResponse.model,
            usage: TokenUsage(
                promptTokens: anthropicResponse.usage.inputTokens,
                completionTokens: anthropicResponse.usage.outputTokens,
                totalTokens: anthropicResponse.usage.inputTokens + anthropicResponse.usage.outputTokens
            )
        )
    }
}

// MARK: - Mistral Transformer
struct MistralRequestTransformer: RequestTransformer {
    func transform(_ request: UnifiedChatRequest) throws -> Data {
        let mistralRequest = MistralRequest(
            model: request.model,
            messages: request.messages.compactMap { message in
                 guard !message.content.isEmpty else { return nil }
                 return MistralMessage(role: message.role, content: message.content)
             },
            temperature: request.parameters.temperature,
            maxTokens: request.parameters.maxTokens,
            topP: request.parameters.topP,
            randomSeed: nil,
            stream: request.parameters.stream
        )
        
        return try JSONEncoder().encode(mistralRequest)
    }
}

struct MistralResponseParser: ResponseParser {
    func parse(_ data: Data) throws -> UnifiedChatResponse {
        let mistralResponse = try JSONDecoder().decode(MistralResponse.self, from: data)
        
        guard let choice = mistralResponse.choices.first,
              !choice.message.content.isEmpty else {
            throw ChatServiceError.invalidResponse
        }
        
        let content = choice.message.content
        
        return UnifiedChatResponse(
            content: content,
            model: mistralResponse.model,
            usage: TokenUsage(
                promptTokens: mistralResponse.usage.promptTokens,
                completionTokens: mistralResponse.usage.completionTokens,
                totalTokens: mistralResponse.usage.totalTokens
            )
        )
    }
}

// MARK: - Grok Transformer
struct GrokRequestTransformer: RequestTransformer {
    func transform(_ request: UnifiedChatRequest) throws -> Data {
        let grokRequest = GrokRequest(
            model: request.model,
            messages: request.messages.compactMap { message in
                 guard !message.content.isEmpty else { return nil }
                 return GrokMessage(role: message.role, content: message.content)
             },
            temperature: request.parameters.temperature,
            maxTokens: request.parameters.maxTokens,
            topP: request.parameters.topP,
            stream: request.parameters.stream
        )
        
        return try JSONEncoder().encode(grokRequest)
    }
}

struct GrokResponseParser: ResponseParser {
    func parse(_ data: Data) throws -> UnifiedChatResponse {
        let grokResponse = try JSONDecoder().decode(GrokResponse.self, from: data)
        
        guard let choice = grokResponse.choices.first,
              !choice.message.content.isEmpty else {
            throw ChatServiceError.invalidResponse
        }
        
        let content = choice.message.content
        
        return UnifiedChatResponse(
            content: content,
            model: grokResponse.model,
            usage: TokenUsage(
                promptTokens: grokResponse.usage.promptTokens,
                completionTokens: grokResponse.usage.completionTokens,
                totalTokens: grokResponse.usage.totalTokens
            )
        )
    }
}

// MARK: - Perplexity Transformer
struct PerplexityRequestTransformer: RequestTransformer {
    func transform(_ request: UnifiedChatRequest) throws -> Data {
        let perplexityRequest = PerplexityRequest(
            model: request.model,
            messages: request.messages.compactMap { message in
                 guard !message.content.isEmpty else { return nil }
                 return PerplexityMessage(role: message.role, content: message.content)
             },
            maxTokens: request.parameters.maxTokens,
            temperature: request.parameters.temperature,
            topP: request.parameters.topP,
            topK: nil,
            stream: request.parameters.stream,
            presencePenalty: nil,
            frequencyPenalty: nil
        )
        
        return try JSONEncoder().encode(perplexityRequest)
    }
}

struct PerplexityResponseParser: ResponseParser {
    func parse(_ data: Data) throws -> UnifiedChatResponse {
        let perplexityResponse = try JSONDecoder().decode(PerplexityResponse.self, from: data)
        
        guard let choice = perplexityResponse.choices.first,
              !choice.message.content.isEmpty else {
            throw ChatServiceError.invalidResponse
        }
        
        let content = choice.message.content
        
        return UnifiedChatResponse(
            content: content,
            model: perplexityResponse.model,
            usage: TokenUsage(
                promptTokens: perplexityResponse.usage.promptTokens,
                completionTokens: perplexityResponse.usage.completionTokens,
                totalTokens: perplexityResponse.usage.totalTokens
            )
        )
    }
}

// MARK: - Using models from BaseHTTPService
// UnifiedChatRequest, ChatMessage, RequestParameters, UnifiedChatResponse, TokenUsage are defined in BaseHTTPService



// MARK: - Protocols (using existing ones from BaseHTTPService)