import Testing
@testable import HolaTalk

@Suite("Application entry screen")
@MainActor
struct AppEntryViewModelTests {
    @Test("Saved practice must load before the chat list appears")
    func waitsForSavedPractice() async {
        let manager = ConversationManager(
            repository: MemoryConversationRepository(archive: nil),
            responder: StubSpanishChat(reply: .success("Hola"))
        )
        let viewModel = AppEntryViewModel(conversations: manager)
        #expect(!viewModel.isLoaded)
        await manager.loadSavedPractice()
        #expect(viewModel.isLoaded)
    }
}
