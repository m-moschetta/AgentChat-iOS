//
//  MistralService.swift
//  AgentChat
//
//  Created by Mario Moschetta on 04/07/25.
//

import Foundation

class MistralService: BaseHTTPService {
    
    // MARK: - Initialization
    init(session: URLSession = .shared) {
        super.init(
            configuration: ProviderConfiguration.mistral,
            requestTransformer: MistralRequestTransformer(),
            responseParser: MistralResponseParser(),
            session: session
        )
    }
    
    // MARK: - Overrides
    override func getKeychainKey() -> String {
        return "mistral"
    }
}