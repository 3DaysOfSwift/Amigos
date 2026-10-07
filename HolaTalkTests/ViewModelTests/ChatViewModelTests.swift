import Testing
@testable import HolaTalk

@Suite("Chat screen")
@MainActor
struct ChatViewModelTests {
    private let context = ChatContext(amigo: Amigo.catalogue[0], scenario: nil)

    @Test("A failed reply leaves the draft available for retry")
    func failedReplyRetainsDraft() async {
        let manager = await makeTestConversationManager(reply: .failure(TestFailure.unavailable))
        let viewModel = ChatViewModel(conversations: manager)
        viewModel.draft = "Hola"
        await viewModel.send(in: context)
        #expect(viewModel.draft == "Hola")
        #expect(viewModel.error != nil)
        #expect(viewModel.conversation(for: context).messages.isEmpty)
    }

    @Test("A saved reply clears the draft and appears in the conversation")
    func successfulReplyClearsDraft() async {
        let manager = await makeTestConversationManager()
        let viewModel = ChatViewModel(conversations: manager)
        viewModel.draft = "Hola"
        await viewModel.send(in: context)
        #expect(viewModel.draft.isEmpty)
        #expect(viewModel.error == nil)
        #expect(viewModel.conversation(for: context).messages.count == 2)
    }
}
