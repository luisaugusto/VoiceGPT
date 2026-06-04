import SwiftData

@Model
final class AppSettings {
    var apiKey: String = ""
    var personalContext: String = ""
    var chatbotPersonality: String = ""
    var accentColor: String = "indigo"
    var vibe: String = "calm"
    var pttStyle: String = "ring"
    var isDarkMode: Bool = true

    init() {}
}
