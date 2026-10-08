import Foundation

@MainActor
final class AppModel {
    static let shared = AppModel.live()

    let conversationsManager: ConversationManager
    let profileManager: ProfileManager
    private var didFinishLaunching = false

    init(conversationsManager: ConversationManager, profileManager: ProfileManager) {
        self.conversationsManager = conversationsManager
        self.profileManager = profileManager
    }

    static func live() -> AppModel {
        AppModel(
            conversationsManager: ConversationManager(
                repository: LocalConversationRepository(),
                responder: OnDeviceSpanishChat()
            ),
            profileManager: ProfileManager(repository: LocalProfileRepository())
        )
    }

    func applicationDidFinishLaunching() async {
        guard !didFinishLaunching else { return }
        didFinishLaunching = true
        async let practice: Void = conversationsManager.loadSavedPractice()
        async let profile: Void = profileManager.loadSavedProfile()
        _ = await (practice, profile)
    }
}
