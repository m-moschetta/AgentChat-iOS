import Foundation

/// Centralized configuration manager handling API keys securely via KeychainService.
class ConfigurationManager {
    static let shared = ConfigurationManager()
    private let keychain = KeychainService.shared

    private init() {}

    // MARK: - Generic Identifier Based Methods
    func setAPIKey(_ key: String, for identifier: String) -> Bool {
        keychain.saveAPIKey(key, for: identifier)
    }

    func getAPIKey(for identifier: String) -> String? {
        keychain.getAPIKey(for: identifier)
    }

    func removeAPIKey(for identifier: String) -> Bool {
        keychain.deleteAPIKey(for: identifier)
    }

    func hasAPIKey(for identifier: String) -> Bool {
        keychain.hasAPIKey(for: identifier)
    }

    func clearAllAPIKeys() -> Bool {
        keychain.clearAllAPIKeys()
    }

    func getAllStoredProviders() -> [String] {
        keychain.getAllStoredProviders()
    }

    // MARK: - AgentType Convenience Methods
    func setAPIKey(_ key: String, for agent: AgentType) -> Bool {
        setAPIKey(key, for: agent.rawValue.lowercased())
    }

    func getAPIKey(for agent: AgentType) -> String? {
        getAPIKey(for: agent.rawValue.lowercased())
    }

    func removeAPIKey(for agent: AgentType) -> Bool {
        removeAPIKey(for: agent.rawValue.lowercased())
    }

    func hasAPIKey(for agent: AgentType) -> Bool {
        hasAPIKey(for: agent.rawValue.lowercased())
    }
}
