import Foundation

actor LocalProfileRepository: ProfileRepository {
    private let fileURL: URL

    init(fileURL: URL = URL.applicationSupportDirectory.appending(path: "HolaTalk/profile.json")) {
        self.fileURL = fileURL
    }

    func load() throws -> LearnerProfile? {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        return try JSONDecoder().decode(LearnerProfile.self, from: Data(contentsOf: fileURL))
    }

    func save(_ profile: LearnerProfile) throws {
        let data = try JSONEncoder().encode(profile)
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: fileURL, options: .atomic)
    }
}
