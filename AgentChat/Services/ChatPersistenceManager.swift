import Foundation

// MARK: - Chat Persistence Manager
class ChatPersistenceManager {
    static let shared = ChatPersistenceManager()

    private let fileURL: URL

    private init() {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        fileURL = directory.appendingPathComponent("chats.json")
    }

    // Save chats to disk
    func saveChats(_ chats: [Chat]) {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(chats)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Errore nel salvataggio delle chat: \(error)")
        }
    }

    // Load chats from disk
    func loadChats() -> [Chat] {
        do {
            let data = try Data(contentsOf: fileURL)
            let chats = try JSONDecoder().decode([Chat].self, from: data)
            // Sort messages chronologically within each chat
            chats.forEach { chat in
                chat.messages.sort { $0.timestamp < $1.timestamp }
            }
            return chats
        } catch {
            return []
        }
    }

    // Export chats to a temporary JSON file
    func exportChats(_ chats: [Chat]) -> URL? {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(chats)
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("agentchat_export.json")
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }

    // Import chats from a JSON file and replace current ones
    func importChats(from url: URL) -> [Chat]? {
        do {
            let data = try Data(contentsOf: url)
            let chats = try JSONDecoder().decode([Chat].self, from: data)
            return chats
        } catch {
            return nil
        }
    }
}
