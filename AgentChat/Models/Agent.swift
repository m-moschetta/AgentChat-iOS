import Foundation

// MARK: - Agent Model
struct Agent: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var description: String
    var instructions: String

    init(id: UUID = UUID(), name: String, description: String = "", instructions: String = "") {
        self.id = id
        self.name = name
        self.description = description
        self.instructions = instructions
    }
}
