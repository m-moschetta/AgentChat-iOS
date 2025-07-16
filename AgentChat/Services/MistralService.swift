//
//  MistralService.swift
//  AgentChat
//
//  Created by Mario Moschetta on 04/07/25.
//

import Foundation

class MistralService: BaseHTTPService {
    
    // MARK: - Initialization
    init() {
        super.init(
            configuration: ProviderConfiguration.mistral,
            requestTransformer: MistralRequestTransformer(),
            responseParser: MistralResponseParser()
        )
    }
    
    // MARK: - Overrides
    override func getKeychainKey() -> String {
        return "mistral"
    }
}