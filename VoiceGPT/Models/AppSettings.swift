import Foundation
import SwiftData

@Model
final class AppSettings {
    var hasAPIKey: Bool = KeychainStore.openAIAPIKey()?.isEmpty == false
    var personalContext: String = ""
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

    func refreshAPIKeyStatus() {
        hasAPIKey = KeychainStore.openAIAPIKey()?.isEmpty == false
    }

    init() {
        self.hasAPIKey = KeychainStore.openAIAPIKey()?.isEmpty == false
    }
}
