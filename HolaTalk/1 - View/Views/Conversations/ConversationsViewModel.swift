import Observation

@MainActor
@Observable
final class ConversationsViewModel {
    private let conversations: any ConversationFeature

    init(conversations: any ConversationFeature = AppModel.shared.conversationsManager) {
        self.conversations = conversations
    }

    var doubloons: Int { conversations.doubloons }
    var amigos: [Amigo] { Amigo.catalogue }
    var currentStreak: Int { conversations.currentStreak }
    var currentWeek: [PracticeDay] { conversations.currentWeek }

    func preview(for amigo: Amigo) -> String {
        let context = ChatContext(amigo: amigo, scenario: nil)
        return conversations.conversation(for: context).messages.last?.text ?? "Start a conversation"
    }
}
