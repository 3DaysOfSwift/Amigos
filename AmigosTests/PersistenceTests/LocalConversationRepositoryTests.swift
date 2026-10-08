import Foundation
import Testing
@testable import Amigos

@Suite("Conversation archive")
struct LocalConversationRepositoryTests {
    @Test("A legacy UserDefaults archive is read and then saved as JSON")
    func migratesLegacyArchive() async throws {
        let suiteName = "AmigosArchiveTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let archive = PracticeArchive(doubloons: 7)
        defaults.set(try JSONEncoder().encode(archive), forKey: "holaTalk.wallet.v1")
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let fileURL = directory.appending(path: "practice.json")
        let repository = LocalConversationRepository(fileURL: fileURL, legacySuiteName: suiteName)
        let loaded = try await repository.load()
        #expect(loaded?.doubloons == 7)
        try await repository.save(try #require(loaded))
        #expect(defaults.data(forKey: "holaTalk.wallet.v1") == nil)
        let reopened = try await LocalConversationRepository(fileURL: fileURL, legacySuiteName: suiteName).load()
        #expect(reopened?.doubloons == 7)
    }

    @Test("Corrupt saved JSON fails without replacing the file")
    func corruptArchiveIsNotDiscarded() async throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let fileURL = directory.appending(path: "practice.json")
        let corruptData = Data("{broken".utf8)
        try corruptData.write(to: fileURL)
        let repository = LocalConversationRepository(fileURL: fileURL)
        await #expect(throws: DecodingError.self) { try await repository.load() }
        #expect(try Data(contentsOf: fileURL) == corruptData)
    }

    @Test("An archive in the original HolaTalk directory is copied into Amigos")
    func migratesOriginalArchiveDirectory() async throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let legacyFileURL = directory.appending(path: "HolaTalk/practice.json")
        let fileURL = directory.appending(path: "Amigos/practice.json")
        try FileManager.default.createDirectory(at: legacyFileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try JSONEncoder().encode(PracticeArchive(doubloons: 12)).write(to: legacyFileURL)

        let repository = LocalConversationRepository(fileURL: fileURL, legacyFileURL: legacyFileURL)
        #expect(try await repository.load()?.doubloons == 12)
        #expect(FileManager.default.fileExists(atPath: fileURL.path))
    }
}
