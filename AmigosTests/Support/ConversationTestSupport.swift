import Foundation
@testable import Amigos

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
    let englishReply: String

    init(reply: Result<String, Error>, englishReply: String = "Hello") {
        self.reply = reply
        self.englishReply = englishReply
    }

    func reply(to message: String, context: ChatContext, history: [ChatMessage]) throws -> SpanishChatReply {
        SpanishChatReply(spanish: try reply.get(), english: englishReply)
    }
}

actor SuspendedSpanishChat: SpanishChatResponding {
    private var response: CheckedContinuation<SpanishChatReply, Error>?
    private var started = false
    private var startWaiter: CheckedContinuation<Void, Never>?

    func reply(to message: String, context: ChatContext, history: [ChatMessage]) async throws -> SpanishChatReply {
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

    func complete(with spanish: String, english: String = "Hello") {
        response?.resume(returning: SpanishChatReply(spanish: spanish, english: english))
        response = nil
    }
}

@MainActor
func makeTestConversationManager(
    archive: PracticeArchive = PracticeArchive(),
    reply: Result<String, Error> = .success("¡Hola! ¿Cómo estás?"),
    englishReply: String = "Hello"
) async -> ConversationManager {
    let manager = ConversationManager(
        repository: MemoryConversationRepository(archive: archive),
        responder: StubSpanishChat(reply: reply, englishReply: englishReply),
        currentDate: { Date(timeIntervalSince1970: 1_780_000_000) }
    )
    await manager.loadSavedPractice()
    return manager
}
