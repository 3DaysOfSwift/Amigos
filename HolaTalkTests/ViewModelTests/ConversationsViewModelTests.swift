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
        #expect(viewModel.currentStreak == manager.currentStreak)
        #expect(viewModel.currentWeek.map(\.id) == manager.currentWeek.map(\.id))
        #expect(viewModel.preview(for: Amigo.catalogue[0]) == "Start a conversation")
    }

    @Test("A chat row previews its latest saved message")
    func previewsLatestMessage() async {
        let amigo = Amigo.catalogue[0]
        let context = ChatContext(amigo: amigo, scenario: nil)
        var archive = PracticeArchive()
        archive.conversations[context.id] = Conversation(messages: [
            ChatMessage(role: .learner, text: "Hola"),
            ChatMessage(role: .storyteller, text: "¡Qué gusto verte!")
        ])
        let manager = await makeTestConversationManager(archive: archive)
        let viewModel = ConversationsViewModel(conversations: manager)

        #expect(viewModel.preview(for: amigo) == "¡Qué gusto verte!")
    }
}
