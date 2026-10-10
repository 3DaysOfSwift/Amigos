import Testing
@testable import Amigos

@Suite("Chat screen")
@MainActor
struct ChatViewModelTests {
    private let context = ChatContext(amigo: Amigo.catalogue[0], scenario: nil)

    @Test("An empty chat offers bilingual starters without an AI request or sending")
    func startingIdeas() async {
        let manager = await makeTestConversationManager(reply: .failure(TestFailure.unavailable))
        let viewModel = ChatViewModel(conversations: manager)
        #expect(!viewModel.suggestedReplies(in: context).isEmpty)
        await viewModel.requestNextReplyIdea(in: context)
        let first = viewModel.draft
        #expect(!first.isEmpty)
        #expect(viewModel.suggestedDraftEnglish(in: context) != nil)
        await viewModel.requestNextReplyIdea(in: context)
        #expect(viewModel.draft != first)
        #expect(manager.conversation(for: context).messages.isEmpty)
        #expect(viewModel.learningError == nil)
        viewModel.draft = "My own greeting"
        #expect(viewModel.suggestedReplies(in: context).isEmpty)
    }

    @Test("Clearing a conversation removes its messages and preserves the draft and balance")
    func clearConversation() async throws {
        let manager = await makeTestConversationManager(reply: .success("Hola"))
        try await manager.send("Hola", in: context)
        let balance = manager.doubloons
        let viewModel = ChatViewModel(conversations: manager)
        viewModel.draft = "Mi mensaje"
        await viewModel.clearConversation(in: context)
        #expect(manager.conversation(for: context).messages.isEmpty)
        #expect(manager.doubloons == balance)
        #expect(viewModel.draft == "Mi mensaje")
        #expect(viewModel.error == nil)
    }

    @Test("Typing appears after its presentation delay without delaying generation")
    func delayedTypingIndicator() async {
        let responder = SuspendedSpanishChat()
        let manager = ConversationManager(repository: MemoryConversationRepository(archive: nil), responder: responder)
        await manager.loadSavedPractice()
        let viewModel = ChatViewModel(conversations: manager, typingPause: { duration in
            #expect(duration == .milliseconds(1_400))
            #expect(manager.isResponding)
        })
        viewModel.draft = "Hola"
        let send = Task { await viewModel.send(in: context) }
        await responder.waitUntilStarted()
        #expect(!viewModel.showsTypingIndicator)
        await viewModel.updateTypingIndicator()
        #expect(viewModel.showsTypingIndicator)
        await responder.complete(with: "Hola, ¿cómo estás?")
        await send.value
        await viewModel.updateTypingIndicator()
        #expect(!viewModel.showsTypingIndicator)
    }

    @Test("A reply completed during the typing delay never shows the dots")
    func fastReplySkipsTypingIndicator() async {
        let responder = SuspendedSpanishChat()
        let manager = ConversationManager(repository: MemoryConversationRepository(archive: nil), responder: responder)
        await manager.loadSavedPractice()
        let send = Task { try? await manager.send("Hola", in: context) }
        await responder.waitUntilStarted()
        let viewModel = ChatViewModel(conversations: manager, typingPause: { _ in
            await responder.complete(with: "Hola, ¿cómo estás?")
            await send.value
        })
        await viewModel.updateTypingIndicator()
        #expect(!viewModel.showsTypingIndicator)
    }

    @Test("A delayed idea never overwrites text typed while learning help loads", .timeLimit(.minutes(1)))
    func editingDuringLearning() async throws {
        let gate = SuspendedSpanishChat()
        let feature = ConversationManager(repository: MemoryConversationRepository(archive: PracticeArchive()),
                                          responder: PausedLearningChat(gate: gate))
        await feature.loadSavedPractice()
        try await feature.send("Hola", in: context)
        let viewModel = ChatViewModel(conversations: feature)
        let task = Task { await viewModel.requestNextReplyIdea(in: context) }
        await gate.waitUntilStarted()
        viewModel.draft = "My own words"
        await gate.complete(with: "Learning help")
        await task.value
        #expect(viewModel.draft == "My own words")
        #expect(!viewModel.isPreparingLearningHelp)
        #expect(!viewModel.isDisplayingReplyIdea)
    }

    @Test("Leaving the chat cancels an idea without filling the draft", .timeLimit(.minutes(1)))
    func cancelledIdea() async throws {
        let gate = SuspendedSpanishChat()
        let feature = ConversationManager(repository: MemoryConversationRepository(archive: PracticeArchive()),
                                          responder: PausedLearningChat(gate: gate))
        await feature.loadSavedPractice()
        try await feature.send("Hola", in: context)
        let viewModel = ChatViewModel(conversations: feature)
        let task = Task { await viewModel.requestNextReplyIdea(in: context) }
        await gate.waitUntilStarted()
        viewModel.cancelOptionalLearningHelp()
        await gate.complete(with: "Late help")
        await task.value
        #expect(viewModel.draft.isEmpty)
        #expect(viewModel.learningError == nil)
        #expect(feature.conversation(for: context).messages.last?.learningHelpPrepared != true)
    }

    @Test("Suggested replies fill the draft without sending and hide while typing")
    func suggestedReplyDraft() async throws {
        let option = SuggestedReply(spanish: "Tuve un día tranquilo.", english: "I had a quiet day.")
        var message = ChatMessage(role: .storyteller, text: "¿Cómo fue tu día?")
        let another = SuggestedReply(spanish: "Fue un día ocupado.", english: "It was a busy day.")
        message.suggestedReplies = [option, another]
        var archive = PracticeArchive()
        archive.conversations[context.id] = Conversation(messages: [message])
        let manager = ConversationManager(repository: MemoryConversationRepository(archive: archive),
            responder: StubSpanishChat(reply: .failure(TestFailure.unavailable)))
        await manager.loadSavedPractice()
        let viewModel = ChatViewModel(conversations: manager)
        #expect(viewModel.suggestedReplies(in: context) == [option, another])
        viewModel.useSuggestedReply(option, in: context)
        #expect(viewModel.draft == option.spanish)
        #expect(viewModel.suggestedDraftEnglish(in: context) == option.english)
        #expect(!viewModel.suggestedReplies(in: context).isEmpty)
        viewModel.useNextReplyIdea(in: context)
        #expect(viewModel.draft == another.spanish)
        #expect(viewModel.suggestedDraftEnglish(in: context) == another.english)
        viewModel.useNextReplyIdea(in: context)
        #expect(viewModel.draft == option.spanish)
        #expect(manager.conversation(for: context).messages == [message])
        #expect(manager.doubloons == archive.doubloons)
        viewModel.draft = "My own words"
        #expect(viewModel.suggestedReplies(in: context).isEmpty)
        #expect(viewModel.suggestedDraftEnglish(in: context) == nil)
        viewModel.useSuggestedReply(option, in: context)
        #expect(viewModel.draft == "My own words")
        viewModel.draft = ""
        #expect(viewModel.suggestedReplies(in: context) == [option, another])
        #expect(viewModel.suggestedDraftEnglish(in: context) == nil)
    }

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
