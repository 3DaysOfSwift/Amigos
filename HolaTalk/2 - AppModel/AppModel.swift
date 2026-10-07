import Foundation

@MainActor
final class AppModel {
    static let shared = AppModel.live()

    let conversationsManager: ConversationManager
    private var didFinishLaunching = false

    init(conversationsManager: ConversationManager) {
        self.conversationsManager = conversationsManager
    }

    static func live() -> AppModel {
        AppModel(conversationsManager: ConversationManager(
            repository: LocalConversationRepository(),
            responder: OnDeviceSpanishChat()
        ))
    }

    func applicationDidFinishLaunching() async {
        guard !didFinishLaunching else { return }
        didFinishLaunching = true
        await conversationsManager.loadSavedPractice()
    }
}
