import Foundation

@MainActor
final class AppModel {
    static let shared = AppModel.live()

    let conversationsManager: ConversationManager
    let profileManager: ProfileManager
    let messageNotificationsManager: MessageNotificationsManager
    private var didFinishLaunching = false

    init(conversationsManager: ConversationManager, profileManager: ProfileManager,
         messageNotificationsManager: MessageNotificationsManager = MessageNotificationsManager()) {
        self.conversationsManager = conversationsManager
        self.profileManager = profileManager
        self.messageNotificationsManager = messageNotificationsManager
    }

    static func live() -> AppModel {
        let profileManager = ProfileManager(repository: LocalProfileRepository())
        let notifications = MessageNotificationsManager()
        return AppModel(
            conversationsManager: ConversationManager(
                repository: LocalConversationRepository(),
                responder: OnDeviceSpanishChat(),
                profileFeature: profileManager,
                notifications: notifications
            ),
            profileManager: profileManager,
            messageNotificationsManager: notifications
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
