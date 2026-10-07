import Foundation

actor LocalConversationRepository: ConversationRepository {
    private let fileURL: URL
    private let legacySuiteName: String?
    private let legacyStorageKey = "holaTalk.wallet.v1"

    init(
        fileURL: URL = URL.applicationSupportDirectory.appending(path: "HolaTalk/practice.json"),
        legacySuiteName: String? = nil
    ) {
        self.fileURL = fileURL
        self.legacySuiteName = legacySuiteName
    }

    func load() throws -> PracticeArchive? {
        if FileManager.default.fileExists(atPath: fileURL.path) {
            return try JSONDecoder().decode(PracticeArchive.self, from: Data(contentsOf: fileURL))
        }
        let defaults = try legacyDefaults()
        guard let legacyData = defaults.data(forKey: legacyStorageKey) else { return nil }
        return try JSONDecoder().decode(PracticeArchive.self, from: legacyData)
    }

    func save(_ archive: PracticeArchive) throws {
        let defaults = try legacyDefaults()
        let data = try JSONEncoder().encode(archive)
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: fileURL, options: .atomic)
        defaults.removeObject(forKey: legacyStorageKey)
    }

    private func legacyDefaults() throws -> UserDefaults {
        guard let legacySuiteName else { return .standard }
        guard let defaults = UserDefaults(suiteName: legacySuiteName) else {
            throw LocalArchiveError.unavailableDefaultsSuite
        }
        return defaults
    }
}

private enum LocalArchiveError: Error {
    case unavailableDefaultsSuite
}
