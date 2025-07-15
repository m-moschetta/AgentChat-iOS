//
//  AnthropicService.swift
//  AgentChat
//
//  Created by Mario Moschetta on 04/07/25.
//

import Foundation

class AnthropicService: BaseHTTPService {
    
    // MARK: - Initialization
    init(session: URLSession = .shared) {
        super.init(
            configuration: .anthropic,
            requestTransformer: AnthropicRequestTransformer(),
            responseParser: AnthropicResponseParser(),
            session: session
        )
    }
    
    // MARK: - Overrides
    override func getKeychainKey() -> String {
        return "anthropic"
    }
}