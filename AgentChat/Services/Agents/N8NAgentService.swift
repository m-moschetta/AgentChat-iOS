//
//  N8NAgentService.swift
//  AgentChat
//
//  Created by Agent on 2024-01-XX.
//

import Foundation

// MARK: - N8N Data Models
struct N8NWorkflowRequest: Codable {
    let workflowId: String
    let input: [String: Any]
    let waitForCompletion: Bool
    
    enum CodingKeys: String, CodingKey {
        case workflowId = "workflow_id"
        case input
        case waitForCompletion = "wait_for_completion"
    }
    
    init(workflowId: String, input: [String: Any], waitForCompletion: Bool) {
        self.workflowId = workflowId
        self.input = input
        self.waitForCompletion = waitForCompletion
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        workflowId = try container.decode(String.self, forKey: .workflowId)
        waitForCompletion = try container.decode(Bool.self, forKey: .waitForCompletion)
        
        // Decode input from JSON string
        if let inputString = try container.decodeIfPresent(String.self, forKey: .input),
           let inputData = inputString.data(using: .utf8) {
            input = try JSONSerialization.jsonObject(with: inputData) as? [String: Any] ?? [:]
        } else {
            input = [:]
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(workflowId, forKey: .workflowId)
        try container.encode(waitForCompletion, forKey: .waitForCompletion)
        
        // Encode input as JSON data
        let inputData = try JSONSerialization.data(withJSONObject: input)
        let inputString = String(data: inputData, encoding: .utf8) ?? "{}"
        try container.encode(inputString, forKey: .input)
    }
}

struct N8NWorkflowResponse: Codable {
    let executionId: String
    let status: String
    let output: [String: Any]?
    let error: String?
    
    enum CodingKeys: String, CodingKey {
        case executionId = "execution_id"
        case status
        case output
        case error
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        executionId = try container.decode(String.self, forKey: .executionId)
        status = try container.decode(String.self, forKey: .status)
        error = try container.decodeIfPresent(String.self, forKey: .error)
        
        // Decode output from JSON string
        if let outputString = try container.decodeIfPresent(String.self, forKey: .output),
           let outputData = outputString.data(using: .utf8) {
            output = try JSONSerialization.jsonObject(with: outputData) as? [String: Any]
        } else {
            output = nil
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(executionId, forKey: .executionId)
        try container.encode(status, forKey: .status)
        try container.encodeIfPresent(error, forKey: .error)
        
        // Encode output as JSON string
        if let output = output {
            let outputData = try JSONSerialization.data(withJSONObject: output)
            let outputString = String(data: outputData, encoding: .utf8) ?? "{}"
            try container.encode(outputString, forKey: .output)
        }
    }
}

// N8NWorkflow is defined in Models/N8NWorkflow.swift

// MARK: - N8N Agent Service
class N8NAgentService: BaseAgentService {
    private let baseURL: String
    private let apiKey: String?
    private let session = URLSession.shared
    
    override var supportedModels: [String] {
        return ["n8n-workflow"]
    }
    
    override var providerName: String {
        return "N8N"
    }
    
    override var capabilities: [AgentCapability] {
        return [.workflowAutomation, .collaboration]
    }
    
    override init(configuration: AgentConfiguration? = nil) {
        let config = configuration ?? AgentConfiguration(
            name: "N8N Workflow Agent",
            systemPrompt: "You are an N8N workflow automation agent. You can execute workflows, manage automations, and integrate with various services.",
            personality: "Efficiente e automatizzato",
            role: "Agente di automazione",
            icon: "⚙️",
            preferredProvider: "N8N"
        )
        
        // Get N8N configuration from environment or defaults
        self.baseURL = ProcessInfo.processInfo.environment["N8N_BASE_URL"] ?? "http://localhost:5678"
        self.apiKey = ProcessInfo.processInfo.environment["N8N_API_KEY"]
        
        super.init(configuration: config)
    }
    
    override func sendMessage(_ message: String, model: String?) async throws -> String {
        // Parse the message to extract workflow information
        let workflowInfo = try parseWorkflowRequest(from: message)
        
        // Execute the workflow
        let response = try await executeWorkflow(
            workflowId: workflowInfo.workflowId,
            input: workflowInfo.input,
            waitForCompletion: workflowInfo.waitForCompletion
        )
        
        // Format the response
        let result = formatWorkflowResponse(response)
        
        // Save conversation context using memory manager
        AgentMemoryManager.shared.saveMemory(
            for: agentConfiguration?.id ?? UUID(),
            chatId: UUID(),
            content: result,
            type: .conversationContext
        )
        
        return result
    }
    
    override func validateConfiguration() async throws {
        guard !baseURL.isEmpty else {
            throw AgentServiceError.invalidConfiguration("N8N base URL is required")
        }
        
        // Test connection to N8N
        // This would be implemented with actual N8N API call
        try await super.validateConfiguration()
    }

    
    // MARK: - N8N-specific methods
    func executeWorkflow(
        workflowId: String,
        input: [String: Any] = [:],
        waitForCompletion: Bool = true
    ) async throws -> N8NWorkflowResponse {
        let url = URL(string: "\(baseURL)/api/v1/workflows/\(workflowId)/execute")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let apiKey = apiKey {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
        
        let workflowRequest = N8NWorkflowRequest(
            workflowId: workflowId,
            input: input,
            waitForCompletion: waitForCompletion
        )
        
        request.httpBody = try JSONEncoder().encode(workflowRequest)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              200...299 ~= httpResponse.statusCode else {
            throw AgentServiceError.networkError(NSError(domain: "N8NError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to execute workflow"]))
        }
        
        return try JSONDecoder().decode(N8NWorkflowResponse.self, from: data)
    }
    
    func listWorkflows() async throws -> [N8NWorkflow] {
        let url = URL(string: "\(baseURL)/api/v1/workflows")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        if let apiKey = apiKey {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              200...299 ~= httpResponse.statusCode else {
            throw AgentServiceError.networkError(NSError(domain: "N8NError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to list workflows"]))
        }
        
        return try JSONDecoder().decode([N8NWorkflow].self, from: data)
    }
    
    func getWorkflowStatus(executionId: String) async throws -> N8NWorkflowResponse {
        let url = URL(string: "\(baseURL)/api/v1/executions/\(executionId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        if let apiKey = apiKey {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              200...299 ~= httpResponse.statusCode else {
            throw AgentServiceError.networkError(NSError(domain: "N8NError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get workflow status"]))
        }
        
        return try JSONDecoder().decode(N8NWorkflowResponse.self, from: data)
    }
    
    // MARK: - Private methods
    private func parseWorkflowRequest(from message: String) throws -> (workflowId: String, input: [String: Any], waitForCompletion: Bool) {
        // Simple parsing logic - in a real implementation, this would be more sophisticated
        // For now, assume the message contains JSON with workflow information
        
        if let data = message.data(using: .utf8),
           let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let workflowId = json["workflowId"] as? String {
            
            let input = json["input"] as? [String: Any] ?? [:]
            let waitForCompletion = json["waitForCompletion"] as? Bool ?? true
            
            return (workflowId, input, waitForCompletion)
        }
        
        // Fallback: treat the entire message as a workflow ID
        return (message.trimmingCharacters(in: .whitespacesAndNewlines), [:], true)
    }
    
    private func formatWorkflowResponse(_ response: N8NWorkflowResponse) -> String {
        var result = "Workflow executed successfully\n"
        result += "Execution ID: \(response.executionId)\n"
        result += "Status: \(response.status)\n"
        
        if let error = response.error {
            result += "Error: \(error)\n"
        }
        
        if let output = response.output {
            result += "Output: \(output)\n"
        }
        
        return result
    }
    
    func getModelInfo() -> [String: Any] {
        return [
            "provider": providerName,
            "supportedModels": supportedModels,
            "defaultModel": "n8n-workflow",
            "capabilities": capabilities.map { $0.rawValue },
            "baseURL": baseURL,
            "apiKeyConfigured": apiKey != nil
        ]
    }
}