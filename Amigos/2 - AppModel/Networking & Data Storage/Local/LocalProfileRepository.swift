import Foundation

actor LocalProfileRepository: ProfileRepository {
    private let fileURL: URL

    init(
        fileURL: URL = URL.applicationSupportDirectory.appending(path: "Amigos/profile.json")
    ) {
        self.fileURL = fileURL
    }

    func load() throws -> LearnerProfile? {
        if FileManager.default.fileExists(atPath: fileURL.path) {
            return try decodeProfile(at: fileURL)
        }
        return nil
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
