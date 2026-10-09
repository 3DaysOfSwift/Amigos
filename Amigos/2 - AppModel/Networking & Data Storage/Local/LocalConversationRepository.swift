import Foundation

actor LocalConversationRepository: ConversationRepository {
    private let fileURL: URL

    init(
        fileURL: URL = URL.applicationSupportDirectory.appending(path: "Amigos/practice.json")
    ) {
        self.fileURL = fileURL
    }

    func load() throws -> PracticeArchive? {
        if FileManager.default.fileExists(atPath: fileURL.path) {
            return try decodeArchive(at: fileURL)
        }
        return nil
    }

    func save(_ archive: PracticeArchive) throws {
        let data = try JSONEncoder().encode(archive)
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: fileURL, options: .atomic)
    }

    private func decodeArchive(at url: URL) throws -> PracticeArchive {
        try JSONDecoder().decode(PracticeArchive.self, from: Data(contentsOf: url))
    }
}
