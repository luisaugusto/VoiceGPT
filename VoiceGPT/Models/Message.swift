import SwiftData
import Foundation

@Model
final class Message {
    var id: UUID = UUID()
    var role: String = "user"
    var text: String = ""
    var createdAt: Date = Date()
    var conversation: Conversation?

    init(role: String, text: String, conversation: Conversation? = nil) {
        self.id = UUID()
        self.role = role
        self.text = text
        self.createdAt = Date()
        self.conversation = conversation
    }
}
