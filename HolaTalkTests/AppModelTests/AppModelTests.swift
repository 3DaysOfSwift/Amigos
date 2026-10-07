import Testing
@testable import HolaTalk

@Suite("AppModel composition")
@MainActor
struct AppModelTests {
    @Test("Application launch loads the same feature graph only once")
    func launchLoadsOnce() async {
        let repository = CountingConversationRepository()
        let manager = ConversationManager(repository: repository, responder: StubSpanishChat(reply: .success("Hola")))
        let appModel = AppModel(conversationsManager: manager)
        await appModel.applicationDidFinishLaunching()
        await appModel.applicationDidFinishLaunching()
        #expect(manager.isLoaded)
        #expect(await repository.loadCount == 1)
    }
}

actor CountingConversationRepository: ConversationRepository {
    private(set) var loadCount = 0
    func load() -> PracticeArchive? { loadCount += 1; return nil }
    func save(_ archive: PracticeArchive) {}
}
