import Foundation
import SwiftData

@Model
final class AppSettings {
    var apiKey: String = ""
    var personalContext: String = ""
    var accentColor: String = "indigo"
    var vibe: String = "calm"
    var pttStyle: String = "ring"
    var isDarkMode: Bool = true

    init() {}

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
