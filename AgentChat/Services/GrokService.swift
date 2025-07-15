//
//  GrokService.swift
//  AgentChat
//
//  Created by Mario Moschetta on 04/07/25.
//

import Foundation

class GrokService: BaseHTTPService {
    
    // MARK: - Initialization
    init(session: URLSession = .shared) {
        super.init(
            configuration: .grok,
            requestTransformer: GrokRequestTransformer(),
            responseParser: GrokResponseParser(),
            session: session
        )
    }
    
    // MARK: - Overrides
    override func getKeychainKey() -> String {
        return "grok"
    }
}