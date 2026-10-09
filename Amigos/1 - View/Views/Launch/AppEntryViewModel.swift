import Observation
import SwiftUI

@MainActor
@Observable
final class AppEntryViewModel {
    private let conversations: any ConversationFeature
    private let currentDate: @MainActor () -> Date
    private let notifications: MessageNotificationsManager
    private var lastBecameInactiveAt: Date?

    init(
        conversations: any ConversationFeature = AppModel.shared.conversationsManager,
        currentDate: @escaping @MainActor () -> Date = { .now },
        notifications: MessageNotificationsManager = AppModel.shared.messageNotificationsManager
    ) {
        self.conversations = conversations
        self.currentDate = currentDate
        self.notifications = notifications
    }

    var isLoaded: Bool { conversations.isLoaded }
    var launchStreak: Int? { conversations.launchStreak }
    var dailyInvitation: DailyAmigoInvitation? { conversations.dailyAmigoInvitation }
    var notificationAmigoID: String? { notifications.pendingAmigoID }

    func takeNotificationChat() -> ChatContext? {
        guard isLoaded, let id = notifications.pendingAmigoID,
              let amigo = conversations.amigos.first(where: { $0.id == id }) else { return nil }
        notifications.pendingAmigoID = nil
        return ChatContext(amigo: amigo, scenario: nil)
    }

    func recordAppBecameInactive() {
        lastBecameInactiveAt = currentDate()
    }

    func shouldPresentStreakMomentAfterReturn() -> Bool {
        guard let lastBecameInactiveAt else { return false }
        self.lastBecameInactiveAt = nil
        guard currentDate().timeIntervalSince(lastBecameInactiveAt) >= 5 * 60 else { return false }

        conversations.prepareStreakLaunch()
        return launchStreak != nil && dailyInvitation != nil
    }
}
