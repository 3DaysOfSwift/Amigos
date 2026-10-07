import Testing
@testable import HolaTalk

@Suite("Conversations screen")
@MainActor
struct ConversationsViewModelTests {
    @Test("The screen exposes the available friends and current wallet")
    func presentsFriendsAndBalance() async {
        let manager = await makeTestConversationManager()
        let viewModel = ConversationsViewModel(conversations: manager)
        #expect(viewModel.amigos.count == Amigo.catalogue.count)
        #expect(viewModel.doubloons == 10)
    }
}
