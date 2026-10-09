import Foundation
import Testing
@testable import Amigos

@Suite("Conversation archive")
struct LocalConversationRepositoryTests {
    @Test("A saved chat archive can be reopened")
    func roundTrip() async throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let fileURL = directory.appending(path: "practice.json")
        let repository = LocalConversationRepository(fileURL: fileURL)
        #expect(try await repository.load() == nil)
        try await repository.save(PracticeArchive(doubloons: 7))
        let reopened = try await LocalConversationRepository(fileURL: fileURL).load()
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

}
