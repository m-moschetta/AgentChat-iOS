//
//  PerplexityService.swift
//  AgentChat
//
//  Created by Mario Moschetta on 04/07/25.
//

import Foundation

class PerplexityService: BaseHTTPService {
    
    // MARK: - Initialization
    init(session: URLSession = .shared) {
        super.init(
            configuration: .perplexity,
            requestTransformer: PerplexityRequestTransformer(),
            responseParser: PerplexityResponseParser(),
            session: session
        )
    }
    
    // MARK: - Overrides
    override func getKeychainKey() -> String {
        return "perplexity"
    }
}