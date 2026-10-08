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
    var amigos: [Amigo] { conversations.amigos }
    var currentStreak: Int { conversations.currentStreak }
    var streakDescription: String { "\(currentStreak) \(currentStreak == 1 ? "day" : "days")" }
    var currentWeek: [PracticeDay] { conversations.currentWeek }
    var searchText = ""
    var visibleAmigos: [Amigo] { conversations.amigos(matching: searchText) }

    func preview(for amigo: Amigo) -> String {
        let context = ChatContext(amigo: amigo, scenario: nil)
        return conversations.conversation(for: context).messages.last?.text ?? "Start a conversation"
    }
}
