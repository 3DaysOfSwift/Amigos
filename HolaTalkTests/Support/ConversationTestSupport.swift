import Foundation
@testable import HolaTalk

enum TestFailure: Error { case unavailable }

actor MemoryConversationRepository: ConversationRepository {
    private var archive: PracticeArchive?
    private var shouldFailSave = false
    private var shouldFailLoad = false

    init(archive: PracticeArchive?) { self.archive = archive }
    func load() throws -> PracticeArchive? {
        if shouldFailLoad { throw TestFailure.unavailable }
        return archive
    }
    func save(_ archive: PracticeArchive) throws {
        if shouldFailSave { shouldFailSave = false; throw TestFailure.unavailable }
        self.archive = archive
    }
    func savedArchive() -> PracticeArchive? { archive }
    func failNextSave() { shouldFailSave = true }
    func failLoad() { shouldFailLoad = true }
}

struct StubSpanishChat: SpanishChatResponding {
    let reply: Result<String, Error>
    func reply(to message: String, context: ChatContext, history: [ChatMessage]) throws -> String {
        try reply.get()
    }
}

actor SuspendedSpanishChat: SpanishChatResponding {
    private var response: CheckedContinuation<String, Error>?
    private var started = false
    private var startWaiter: CheckedContinuation<Void, Never>?

    func reply(to message: String, context: ChatContext, history: [ChatMessage]) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            response = continuation
            started = true
            startWaiter?.resume()
            startWaiter = nil
        }
    }

    func waitUntilStarted() async {
        guard !started else { return }
        await withCheckedContinuation { continuation in startWaiter = continuation }
    }

    func complete(with text: String) {
        response?.resume(returning: text)
        response = nil
    }
}

@MainActor
func makeTestConversationManager(
    archive: PracticeArchive = PracticeArchive(),
    reply: Result<String, Error> = .success("¡Hola! ¿Cómo estás?")
) async -> ConversationManager {
    let manager = ConversationManager(
        repository: MemoryConversationRepository(archive: archive),
        responder: StubSpanishChat(reply: reply),
        currentDate: { Date(timeIntervalSince1970: 1_780_000_000) }
    )
    await manager.loadSavedPractice()
    return manager
}
