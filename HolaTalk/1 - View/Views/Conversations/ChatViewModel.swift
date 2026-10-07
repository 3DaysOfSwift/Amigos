import Foundation
import Observation

@MainActor
@Observable
final class ChatViewModel {
    private let conversations: any ConversationFeature
    var draft = ""
    private(set) var error: String?
    private(set) var isSending = false
    private(set) var pendingMessage: ChatMessage?

    init(conversations: any ConversationFeature = AppModel.shared.conversationsManager) {
        self.conversations = conversations
    }

    func conversation(for context: ChatContext) -> Conversation {
        conversations.conversation(for: context)
    }

    var doubloons: Int { conversations.doubloons }
    var currentStreak: Int { conversations.currentStreak }
    var currentWeek: [PracticeDay] { conversations.currentWeek }

    func canSend(in context: ChatContext) -> Bool {
        !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !isSending && !conversations.isResponding
            && conversations.canStart(context)
            && !conversation(for: context).finished
    }

    func isResponding() -> Bool { conversations.isResponding }
    func canClaimReward(in context: ChatContext) -> Bool { conversations.canClaimDailyChatReward(in: context) }
    func canFinishRolePlay(in context: ChatContext) -> Bool { conversations.canFinishRolePlay(context) }
    func hasEnoughDoubloons(for context: ChatContext) -> Bool { conversations.canStart(context) }
    func isConversationActive(_ context: ChatContext) -> Bool {
        conversations.isConversationActive(context)
    }

    func send(in context: ChatContext) async {
        guard !isSending else { return }
        let message = draft
        error = nil
        isSending = true
        pendingMessage = ChatMessage(role: .learner, text: message)
        defer { isSending = false; pendingMessage = nil }
        do {
            try await conversations.send(message, in: context)
            draft = ""
        } catch is CancellationError {
            // A cancelled response leaves the draft ready to send again.
        } catch {
            self.error = error.localizedDescription
        }
    }

    func finishRolePlay(in context: ChatContext) async {
        do { try await conversations.finishRolePlay(context) }
        catch { self.error = error.localizedDescription }
    }

    func claimReward(in context: ChatContext) async {
        do { try await conversations.claimDailyChatReward(in: context) }
        catch { self.error = error.localizedDescription }
    }

    func practiseAgain(_ context: ChatContext) async {
        do { try await conversations.practiseAgain(context) }
        catch { self.error = error.localizedDescription }
    }
}
