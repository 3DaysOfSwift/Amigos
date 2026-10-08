import Observation

@MainActor
@Observable
final class AppEntryViewModel {
    private let conversations: any ConversationFeature

    init(conversations: any ConversationFeature = AppModel.shared.conversationsManager) {
        self.conversations = conversations
    }

    var isLoaded: Bool { conversations.isLoaded }
    var loadError: String? { conversations.loadError }
    func retryLoading() async {
        await conversations.loadSavedPractice()
    }
}
