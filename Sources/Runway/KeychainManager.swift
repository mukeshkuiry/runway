import Foundation

/// Stores OAuth tokens in a local file in Application Support directory
/// Avoids Keychain prompts for unsigned debug builds
final class KeychainManager {
    private static let folderName = "Runway"
    private static let fileName = "tokens.dat"

    private static var storageURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let folder = appSupport.appendingPathComponent(folderName)

        if !FileManager.default.fileExists(atPath: folder.path) {
            try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        }

        return folder.appendingPathComponent(fileName)
    }

    private static func loadAll() -> [String: String] {
        guard let data = try? Data(contentsOf: storageURL),
              let dict = try? JSONDecoder().decode([String: String].self, from: data)
        else { return [:] }
        return dict
    }

    private static func saveAll(_ dict: [String: String]) {
        guard let data = try? JSONEncoder().encode(dict) else { return }
        try? data.write(to: storageURL, options: [.atomic, .completeFileProtection])
    }

    static func save(key: String, value: String) {
        var dict = loadAll()
        dict[key] = value
        saveAll(dict)
    }

    static func load(key: String) -> String? {
        return loadAll()[key]
    }

    static func delete(key: String) {
        var dict = loadAll()
        dict.removeValue(forKey: key)
        saveAll(dict)
    }
}
