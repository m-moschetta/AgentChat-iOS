//
//  OpenAIService.swift
//  AgentChat
//
//  Created by Mario Moschetta on 04/07/25.
//

import Foundation

class OpenAIService: BaseHTTPService {
    
    // MARK: - Initialization
    init(session: URLSession = .shared) {
        super.init(
            configuration: .openAI,
            requestTransformer: OpenAIRequestTransformer(),
            responseParser: OpenAIResponseParser(),
            session: session
        )
    }
    
    // MARK: - Overrides
    override func getKeychainKey() -> String {
        return "openai"
    }
}