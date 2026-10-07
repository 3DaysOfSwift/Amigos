import Observation

@MainActor
@Observable
final class RolePlayViewModel {
    private let conversations: any ConversationFeature

    init(conversations: any ConversationFeature = AppModel.shared.conversationsManager) {
        self.conversations = conversations
    }

    var doubloons: Int { conversations.doubloons }
    var options: [RolePlayOption] { conversations.rolePlayOptions }
}
