import Foundation
import Security

enum KeychainStore {
    private static let service = Bundle.main.bundleIdentifier ?? "VoiceGPT"
    private static let openAIAccount = "openai-api-key"

    static func openAIAPIKey() -> String? {
        string(account: openAIAccount)
    }

    static func setOpenAIAPIKey(_ apiKey: String) {
        setString(apiKey.trimmingCharacters(in: .whitespacesAndNewlines), account: openAIAccount)
    }

    private static func string(account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnData as String: true
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess,
              let data = item as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }
        return value
    }

    private static func setString(_ value: String, account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        if value.isEmpty {
            SecItemDelete(query as CFDictionary)
            return
        }

        let attributes: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            kSecValueData as String: Data(value.utf8)
        ]

        let update: [String: Any] = [
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            kSecValueData as String: Data(value.utf8)
        ]

        let status = SecItemUpdate(query as CFDictionary, update as CFDictionary)
        if status == errSecItemNotFound {
            SecItemAdd(attributes as CFDictionary, nil)
        }
    }
}
