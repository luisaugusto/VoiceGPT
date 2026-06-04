import Foundation
import SwiftData

@Model
final class AppSettings {
    static let defaultAccentColor = "indigo"
    static let defaultVibe = "calm"
    static let defaultPTTStyle = "ring"

    var hasAPIKey: Bool = KeychainStore.openAIAPIKey()?.isEmpty == false
    var personalContext: String = ""
    var chatbotPersonality: String = ""
    var speechVoice: String = "alloy"
    var accentColor: String = defaultAccentColor
    var vibe: String = defaultVibe
    var pttStyle: String = defaultPTTStyle

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
