//
//  ChatServiceProtocol.swift
//  AgentChat
//
//  Created by Mario Moschetta on 04/07/25.
//

import Foundation

// MARK: - Chat Service Protocol
protocol ChatServiceProtocol {
    func sendMessage(_ message: String, configuration: AgentConfiguration) async throws -> String
    func validateConfiguration() async throws
    var supportedModels: [String] { get }
    var providerName: String { get }
}