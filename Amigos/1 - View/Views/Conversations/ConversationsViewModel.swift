import Foundation
import Observation

@MainActor
@Observable
final class ConversationsViewModel {
    private let conversations: any ConversationFeature

    init(conversations: any ConversationFeature = AppModel.shared.conversationsManager) {
        self.conversations = conversations
    }

    var doubloons: Int { conversations.doubloons }
    var isLoaded: Bool { conversations.isLoaded }
    var loadError: String? { conversations.loadError }
    private(set) var isRetrying = false
    private(set) var introductionError: String?
    var amigos: [Amigo] { conversations.amigos }
    var currentStreak: Int { conversations.currentStreak }
    var streakDescription: String { "\(currentStreak) \(currentStreak == 1 ? "day" : "days")" }
    var hasCompletedDayStreak: Bool { conversations.hasCompletedDayStreak }
    var streakStatusDescription: String {
        guard !hasCompletedDayStreak else { return "Complete" }
        let remaining = conversations.messagesRemainingForDayStreak
        return "\(remaining) \(remaining == 1 ? "message" : "messages") required"
    }
    var currentWeek: [PracticeDay] { conversations.currentWeek }
    var searchText = ""
    var visibleAmigos: [Amigo] { conversations.amigos(matching: searchText) }

    func preview(for amigo: Amigo) -> String {
        guard isLoaded else { return loadError == nil ? "Loading conversation…" : "Conversation unavailable" }
        let context = ChatContext(amigo: amigo, scenario: nil)
        return conversations.conversation(for: context).messages.last?.text ?? "Start a conversation"
    }

    func retryLoading() {
        guard !isRetrying else { return }
        isRetrying = true
        Task {
            defer { isRetrying = false }
            await conversations.loadSavedPractice()
        }
    }

    func introduceAmigos() async {
        guard isLoaded else { return }
        do {
            try await Task.sleep(for: .seconds(1))
            try Task.checkCancellation()
            try await conversations.introduceFirstAmigo()
            introductionError = nil
        } catch is CancellationError {
            // Try again when Chats is visible; no welcome is recorded until it is saved.
        } catch {
            introductionError = error.localizedDescription
        }
    }
}
