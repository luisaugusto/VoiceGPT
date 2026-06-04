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

    func refreshAPIKeyStatus() {
        hasAPIKey = KeychainStore.openAIAPIKey()?.isEmpty == false
    }

    init() {
        self.hasAPIKey = KeychainStore.openAIAPIKey()?.isEmpty == false
    }
}
