import Foundation
import Testing
@testable import HolaTalk

@Suite("Local learner profile")
struct LocalProfileRepositoryTests {
    @Test("A saved profile can be reopened")
    func roundTrip() async throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: "ProfileTests-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: directory) }
        let fileURL = directory.appending(path: "profile.json")
        let repository = LocalProfileRepository(fileURL: fileURL)
        #expect(try await repository.load() == nil)
        try await repository.save(LearnerProfile(displayName: "Alex"))
        let reopened = LocalProfileRepository(fileURL: fileURL)
        #expect(try await reopened.load()?.displayName == "Alex")
    }

    @Test("Corrupt saved data is reported, not treated as a new profile")
    func corruptProfile() async throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: "ProfileTests-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let fileURL = directory.appending(path: "profile.json")
        let original = Data("not valid JSON".utf8)
        try original.write(to: fileURL)
        let repository = LocalProfileRepository(fileURL: fileURL)
        await #expect(throws: Error.self) { try await repository.load() }
        #expect(try Data(contentsOf: fileURL) == original)
    }
}
