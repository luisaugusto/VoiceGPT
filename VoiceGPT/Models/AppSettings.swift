import Foundation
import SwiftData

@Model
final class AppSettings {
    var hasAPIKey: Bool = KeychainStore.openAIAPIKey()?.isEmpty == false
    var personalContext: String = ""
    var chatbotPersonality: String = ""
    var speechVoice: String = "alloy"
    var accentColor: String = "indigo"
    var vibe: String = "calm"
    var pttStyle: String = "ring"
    var isDarkMode: Bool = true

    var apiKey: String {
        get { KeychainStore.openAIAPIKey() ?? "" }
        set {
            KeychainStore.setOpenAIAPIKey(newValue)
            hasAPIKey = !newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    init() {
        self.hasAPIKey = KeychainStore.openAIAPIKey()?.isEmpty == false
    }

    func refreshAPIKeyStatus() {
        hasAPIKey = KeychainStore.openAIAPIKey()?.isEmpty == false
    }

    @discardableResult
    func appendPersonalContext(_ newContext: String) -> Bool {
        let cleanedContext = newContext.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedContext.isEmpty else { return false }

        let existingContext = personalContext.trimmingCharacters(in: .whitespacesAndNewlines)
        if existingContext.localizedCaseInsensitiveContains(cleanedContext) {
            return false
        }

        personalContext = existingContext.isEmpty
            ? cleanedContext
            : "\(existingContext)\n\(cleanedContext)"
        return true
    }
}
