import Testing
@testable import Amigos

@Suite("Chat screen")
@MainActor
struct ChatViewModelTests {
    private let context = ChatContext(amigo: Amigo.catalogue[0], scenario: nil)

    @Test("Sending clears the composer before the reply and preserves a new draft")
    func composerClearsWhileAwaitingReply() async {
        let responder = SuspendedSpanishChat()
        let manager = ConversationManager(repository: MemoryConversationRepository(archive: nil), responder: responder)
        await manager.loadSavedPractice()
        let viewModel = ChatViewModel(conversations: manager)
        viewModel.draft = "Hola"
        let sending = Task { await viewModel.send(in: context) }
        await responder.waitUntilStarted()
        #expect(viewModel.draft.isEmpty)
        #expect(viewModel.pendingMessage?.text == "Hola")
        #expect(viewModel.isSending)
        viewModel.draft = "¿Qué tal?"
        await responder.complete(with: "¡Hola!")
        await sending.value
        #expect(viewModel.draft == "¿Qué tal?")
        #expect(viewModel.pendingMessage == nil)
    }

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

    @Test("Tapping an AI reply reveals and hides its saved English translation")
    func translationToggle() async {
        let message = ChatMessage(role: .storyteller, text: "¡Hola!", englishText: "Hello!")
        var archive = PracticeArchive()
        archive.conversations[context.id] = Conversation(messages: [message])
        let manager = await makeTestConversationManager(archive: archive)
        let viewModel = ChatViewModel(conversations: manager)

        viewModel.toggleTranslation(for: message)
        #expect(viewModel.translationDisplay(for: message) == .translated("Hello!"))
        viewModel.toggleTranslation(for: message)
        #expect(viewModel.translationDisplay(for: message) == .hidden)
        viewModel.toggleTranslation(for: message)
        #expect(viewModel.translationDisplay(for: message) == .translated("Hello!"))
    }

    @Test("A learner message without an English counterpart does not reveal a translation")
    func learnerMessageDoesNotRevealTranslation() async {
        let message = ChatMessage(role: .learner, text: "¡Hola!")
        var archive = PracticeArchive()
        archive.conversations[context.id] = Conversation(messages: [message])
        let manager = await makeTestConversationManager(archive: archive)
        let viewModel = ChatViewModel(conversations: manager)
        viewModel.toggleTranslation(for: message)
        #expect(viewModel.translationDisplay(for: message) == .hidden)
    }

    @Test("Role Play admission celebrates before revealing the composer")
    func admissionCelebration() async {
        let context = ChatContext(amigo: Amigo.catalogue[0], scenario: RolePlayScenario.catalogue[0])
        let manager = await makeTestConversationManager()
        let viewModel = ChatViewModel(conversations: manager, admissionPause: { _ in })
        #expect(viewModel.showsRolePlayAdmission(context))
        #expect(viewModel.authorizeRolePlay(context))
        #expect(viewModel.admissionSuccess == 1)
        await viewModel.waitForAdmissionAnimation()
        #expect(viewModel.admissionPhase == .finished)
        #expect(!viewModel.showsRolePlayAdmission(context))
        #expect(manager.canStart(context))
    }
}
