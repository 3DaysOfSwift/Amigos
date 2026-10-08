import Foundation

actor LocalProfileRepository: ProfileRepository {
    private let fileURL: URL
    private let legacyFileURL: URL?

    init(
        fileURL: URL = URL.applicationSupportDirectory.appending(path: "Amigos/profile.json"),
        legacyFileURL: URL? = URL.applicationSupportDirectory.appending(path: "HolaTalk/profile.json")
    ) {
        self.fileURL = fileURL
        self.legacyFileURL = legacyFileURL
    }

    func load() throws -> LearnerProfile? {
        if FileManager.default.fileExists(atPath: fileURL.path) {
            return try decodeProfile(at: fileURL)
        }
        guard let legacyFileURL, FileManager.default.fileExists(atPath: legacyFileURL.path) else { return nil }

        let profile = try decodeProfile(at: legacyFileURL)
        try save(profile)
        return profile
    }

    func save(_ profile: LearnerProfile) throws {
        let data = try JSONEncoder().encode(profile)
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: fileURL, options: .atomic)
    }

    private func decodeProfile(at url: URL) throws -> LearnerProfile {
        try JSONDecoder().decode(LearnerProfile.self, from: Data(contentsOf: url))
    }
}
