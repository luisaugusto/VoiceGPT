import SwiftData
import Foundation

@Model
final class Conversation {
    var id: UUID = UUID()
    var title: String = "New conversation"
    var createdAt: Date = Date()

    @Relationship(deleteRule: .cascade, inverse: \Message.conversation)
    var messages: [Message] = []

    init(title: String = "New conversation") {
        self.id = UUID()
        self.title = title
        self.createdAt = Date()
        self.messages = []
    }

    var sortedMessages: [Message] {
        messages.sorted { $0.createdAt < $1.createdAt }
    }

    var preview: String {
        sortedMessages.last?.text.prefix(60).description ?? ""
    }

    func matchesSearch(_ query: String) -> Bool {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return true }

        if title.localizedCaseInsensitiveContains(trimmedQuery) {
            return true
        }

        return messages.contains { message in
            message.text.localizedCaseInsensitiveContains(trimmedQuery)
        }
    }
}
