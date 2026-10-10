import Foundation
import Observation

@MainActor
@Observable
final class ChatViewModel {
    enum AdmissionPhase: Equatable {
        case ready, accepted, centering, confirmed, dismissing, finished
    }

    enum TranslationDisplay: Equatable {
        case hidden, translated(String)
    }

    private let conversations: any ConversationFeature
    private let admissionPause: @MainActor (Duration) async throws -> Void
    private let typingPause: @MainActor (Duration) async throws -> Void
    private(set) var showsTypingIndicator = false
    private var admissionTask: Task<Void, Never>?
    private var learningTask: Task<Bool, Never>?
    private(set) var isPreparingLearningHelp = false
    private(set) var learningError: String?
    private(set) var translatingMessageID: UUID?
    private var visibleTranslationIDs: Set<UUID> = []
    private var insertedReplyIdea: String?
    private var replyIdeaMessageID: UUID?
    var draft = "" {
        didSet {
            if draft != insertedReplyIdea {
                insertedReplyIdea = nil
                replyIdeaMessageID = nil
            }
        }
    }
    private(set) var error: String?
    private(set) var isSending = false
    private(set) var isAnsweringNotificationInvitation = false
    private(set) var greetingFailed = false
    private(set) var pendingMessage: ChatMessage?
    private var messageBeforeSendingID: UUID?

    func visiblePendingMessage(in context: ChatContext) -> ChatMessage? {
        guard conversations.conversation(for: context).messages.last?.id == messageBeforeSendingID else { return nil }
        return pendingMessage
    }
    private(set) var admissionPhase: AdmissionPhase = .ready
    private(set) var admissionSuccess = 0

    init(
        conversations: any ConversationFeature = AppModel.shared.conversationsManager,
        admissionPause: @escaping @MainActor (Duration) async throws -> Void = { try await Task.sleep(for: $0) },
        typingPause: @escaping @MainActor (Duration) async throws -> Void = { try await Task.sleep(for: $0) }
    ) {
        self.conversations = conversations
        self.admissionPause = admissionPause
        self.typingPause = typingPause
    }

    /// Presentation only: generation is already running independently of this delay.
    func updateTypingIndicator() async {
        showsTypingIndicator = false
        guard conversations.isResponding else { return }
        do {
            try await typingPause(.milliseconds(1_400))
            try Task.checkCancellation()
            showsTypingIndicator = conversations.isResponding
        } catch { }
    }

    func conversation(for context: ChatContext) -> Conversation {
        conversations.conversation(for: context)
    }

    func clearConversation(in context: ChatContext) async {
        guard !isSending else { return }
        isSending = true
        defer { isSending = false }
        error = nil
        do {
            await cancelLearningHelp()
            try await conversations.clearConversation(context)
            visibleTranslationIDs.removeAll()
            insertedReplyIdea = nil
            replyIdeaMessageID = nil
            learningError = nil
            await startSuggestedChat(context)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func startSuggestedChat(_ context: ChatContext) async {
        greetingFailed = false
        error = nil
        var greetingContext = context
        greetingContext.startsWithGreeting = true
        do { try await conversations.startSuggestedChat(greetingContext) }
        catch is CancellationError { }
        catch {
            greetingFailed = true
            self.error = error.localizedDescription
        }
    }

    var doubloons: Int { conversations.doubloons }
    var isDisplayingReplyIdea: Bool {
        insertedReplyIdea != nil && draft == insertedReplyIdea
    }
    func suggestedDraftEnglish(in context: ChatContext) -> String? {
        guard isDisplayingReplyIdea else { return nil }
        return suggestedReplies(in: context).first { $0.spanish == draft }?.english
    }
    func suggestedReplies(in context: ChatContext) -> [SuggestedReply] {
        let conversation = conversations.conversation(for: context)
        guard !isSending, !conversations.isResponding,
              !conversation.finished, !showsRolePlayAdmission(context) else { return [] }
        if conversation.messages.isEmpty && context.scenario == nil {
            guard draft.isEmpty || isDisplayingReplyIdea else { return [] }
            return [
                SuggestedReply(spanish: "¡Hola, \(context.amigo.name)! ¿Cómo estás?", english: "Hi, \(context.amigo.name)! How are you?"),
                SuggestedReply(spanish: "¡Hola! ¿Qué tal tu día?", english: "Hi! How is your day going?"),
                SuggestedReply(spanish: "¡Hola! Tengo ganas de practicar español contigo.", english: "Hi! I feel like practising Spanish with you.")
            ]
        }
        guard let last = conversation.messages.last, last.role == .storyteller else { return [] }
        guard draft.isEmpty || (draft == insertedReplyIdea && replyIdeaMessageID == last.id) else { return [] }
        let replies = last.suggestedReplies ?? []
        return replies.isEmpty ? SuggestedReply.learningHelp : replies
    }

    func useSuggestedReply(_ suggestion: SuggestedReply, in context: ChatContext) {
        guard suggestedReplies(in: context).contains(suggestion) else { return }
        insertedReplyIdea = suggestion.spanish
        replyIdeaMessageID = conversations.conversation(for: context).messages.last?.id
        draft = suggestion.spanish
    }

    func useNextReplyIdea(in context: ChatContext) {
        let replies = suggestedReplies(in: context)
        guard !replies.isEmpty else { return }
        let nextIndex: Int
        if let currentIndex = replies.firstIndex(where: { $0.spanish == draft }) {
            nextIndex = (currentIndex + 1) % replies.count
        } else {
            nextIndex = 0
        }
        useSuggestedReply(replies[nextIndex], in: context)
    }

    func requestNextReplyIdea(in context: ChatContext) async {
        guard !isPreparingLearningHelp, !suggestedReplies(in: context).isEmpty else { return }
        if conversation(for: context).messages.isEmpty {
            useNextReplyIdea(in: context)
            return
        }
        let originalDraft = draft
        let messageID = conversation(for: context).messages.last?.id
        let prepared = await prepareLearningHelp(in: context)
        guard prepared, !Task.isCancelled, learningError == nil, draft == originalDraft,
              conversation(for: context).messages.last?.id == messageID else { return }
        useNextReplyIdea(in: context)
    }

    @discardableResult
    func prepareLearningHelp(in context: ChatContext) async -> Bool {
        guard learningTask == nil, !isSending else { return false }
        learningError = nil
        isPreparingLearningHelp = true
        let task = Task {
            do {
                try await conversations.prepareLearningHelp(in: context)
                try Task.checkCancellation()
                return true
            }
            catch is CancellationError { return false }
            catch { learningError = error.localizedDescription; return false }
        }
        learningTask = task
        let prepared = await task.value
        learningTask = nil
        isPreparingLearningHelp = false
        return prepared
    }

    private func cancelLearningHelp() async {
        learningTask?.cancel()
        _ = await learningTask?.value
    }

    func cancelOptionalLearningHelp() { learningTask?.cancel() }

    func prepareHello(in context: ChatContext) {
        guard draft.isEmpty, !isSending, !conversations.isResponding,
              context.scenario == nil,
              conversations.conversation(for: context).messages.isEmpty else { return }
        draft = "¡Hola! ¿Cómo estás?"
    }

    func startNewConversation(in context: ChatContext) async {
        guard !isSending else { return }
        isSending = true
        defer { isSending = false }
        await cancelLearningHelp()
        do {
            try await conversations.startNewConversation(context)
            error = nil
            greetingFailed = false
            visibleTranslationIDs.removeAll()
        } catch {
            self.error = error.localizedDescription
        }
    }
    var profileNotice: String? { conversations.profileNotice }
    func offersNotificationPermission(in context: ChatContext) -> Bool {
        conversations.offersNotificationPermission(in: context)
    }

    func answerNotificationInvitation(enable: Bool) async {
        guard !isAnsweringNotificationInvitation else { return }
        isAnsweringNotificationInvitation = true
        defer { isAnsweringNotificationInvitation = false }
        error = nil
        do { try await conversations.answerNotificationInvitation(enable: enable) }
        catch { self.error = error.localizedDescription }
    }
    func canSend(in context: ChatContext) -> Bool {
        !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !isSending && !conversations.isResponding
            && conversations.canStart(context)
            && !conversation(for: context).finished
    }

    func isResponding() -> Bool { conversations.isResponding }
    func canFinishRolePlay(in context: ChatContext) -> Bool { conversations.canFinishRolePlay(context) }
    func canAuthorizeRolePlay(_ context: ChatContext) -> Bool { conversations.canAuthorizeRolePlay(context) }
    func needsRolePlayAdmission(_ context: ChatContext) -> Bool {
        context.scenario != nil && !conversations.canStart(context)
            && !conversations.isConversationActive(context)
    }
    func showsRolePlayAdmission(_ context: ChatContext) -> Bool {
        guard context.scenario != nil else { return false }
        switch admissionPhase {
        case .ready: return needsRolePlayAdmission(context)
        case .accepted, .centering, .confirmed: return true
        case .dismissing, .finished: return false
        }
    }

    var isCelebratingAdmission: Bool {
        admissionPhase == .centering || admissionPhase == .confirmed
    }

    func authorizeRolePlay(_ context: ChatContext) -> Bool {
        guard admissionPhase == .ready else { return false }
        error = nil
        guard conversations.authorizeRolePlay(context) else { return false }
        admissionPhase = .accepted
        admissionSuccess += 1
        admissionTask = Task {
            do {
                try await admissionPause(.milliseconds(120))
                try Task.checkCancellation()
                admissionPhase = .centering
                try await admissionPause(.milliseconds(300))
                try Task.checkCancellation()
                admissionPhase = .confirmed
                try await admissionPause(.milliseconds(350))
                try Task.checkCancellation()
                admissionPhase = .dismissing
                try await admissionPause(.milliseconds(430))
                try Task.checkCancellation()
                admissionPhase = .finished
                admissionTask = nil
            } catch {
                // Navigation cancels the presentation; the authorization remains ready to use.
            }
        }
        return true
    }

    func waitForAdmissionAnimation() async { await admissionTask?.value }

    func cancelAdmissionAnimation() {
        admissionTask?.cancel()
        admissionTask = nil
        if admissionPhase != .ready { admissionPhase = .finished }
    }

    func translationDisplay(for message: ChatMessage) -> TranslationDisplay {
        guard visibleTranslationIDs.contains(message.id), let englishText = message.englishText else { return .hidden }
        return .translated(englishText)
    }

    func toggleTranslation(for message: ChatMessage) {
        guard message.englishText != nil else { return }
        if visibleTranslationIDs.contains(message.id) {
            visibleTranslationIDs.remove(message.id)
        } else {
            visibleTranslationIDs.insert(message.id)
        }
    }
    func revealTranslation(for message: ChatMessage, in context: ChatContext) async {
        if message.englishText != nil {
            toggleTranslation(for: message)
            return
        }
        guard translatingMessageID == nil, !isSending, !isResponding() else { return }
        translatingMessageID = message.id
        isSending = true
        error = nil
        defer { translatingMessageID = nil; isSending = false }
        do {
            await cancelLearningHelp()
            try await conversations.translateMessage(message.id, in: context)
            visibleTranslationIDs.insert(message.id)
        } catch is CancellationError { }
        catch { self.error = error.localizedDescription }
    }
    func isConversationActive(_ context: ChatContext) -> Bool {
        conversations.isConversationActive(context)
    }

    func acceptWritingSuggestion(_ suggestion: WritingSuggestion, messageID: UUID, in context: ChatContext) async {
        guard !isSending else { return }
        isSending = true
        error = nil
        defer { isSending = false }
        await cancelLearningHelp()
        do { try await conversations.acceptWritingSuggestion(suggestion, messageID: messageID, in: context) }
        catch is CancellationError { }
        catch { self.error = error.localizedDescription }
    }

    func send(in context: ChatContext) async {
        guard !isSending else { return }
        let message = draft
        error = nil
        isSending = true
        messageBeforeSendingID = conversations.conversation(for: context).messages.last?.id
        pendingMessage = ChatMessage(role: .learner, text: message)
        draft = ""
        defer { isSending = false; pendingMessage = nil }
        do {
            await cancelLearningHelp()
            try await conversations.send(message, in: context)
        } catch is CancellationError {
            draft = draft.isEmpty ? message : message + "\n" + draft
        } catch {
            draft = draft.isEmpty ? message : message + "\n" + draft
            self.error = error.localizedDescription
        }
    }

    func finishRolePlay(in context: ChatContext) async {
        do { try await conversations.finishRolePlay(context) }
        catch { self.error = error.localizedDescription }
    }

    func practiseAgain(_ context: ChatContext) async {
        do { try await conversations.practiseAgain(context) }
        catch { self.error = error.localizedDescription }
    }
}
