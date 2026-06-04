import Foundation

enum SecureFileStore {
    private static let directoryName = "ProtectedAudio"

    static func uniqueFileURL(fileExtension: String) throws -> URL {
        try secureDirectory()
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension(fileExtension)
    }

    static func write(_ data: Data, to url: URL) throws {
        try data.write(to: url, options: [.atomic, .completeFileProtection])
        try protectItem(at: url)
    }

    static func removeItem(at url: URL) {
        try? FileManager.default.removeItem(at: url)
    }

    private static func secureDirectory() throws -> URL {
        guard let baseDirectory = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else {
            throw CocoaError(.fileNoSuchFile)
        }

        let directory = baseDirectory.appendingPathComponent(directoryName, isDirectory: true)
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        try protectItem(at: directory)
        try excludeFromBackup(directory)
        return directory
    }

    private static func protectItem(at url: URL) throws {
        try FileManager.default.setAttributes(
            [.protectionKey: FileProtectionType.complete],
            ofItemAtPath: url.path
        )
    }

    private static func excludeFromBackup(_ url: URL) throws {
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        var mutableURL = url
        try mutableURL.setResourceValues(values)
    }
}
