import Foundation
import Observation
import UserNotifications

@MainActor
protocol AmigoMessageNotifying: AnyObject {
    func requestPermission() async throws -> Bool
    func notify(amigo: Amigo, message: ChatMessage) async
}

@MainActor
@Observable
final class MessageNotificationsManager: AmigoMessageNotifying {
    var pendingAmigoID: String?
    private(set) var deliveryError: String?

    func requestPermission() async throws -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        if settings.authorizationStatus == .notDetermined {
            return try await center.requestAuthorization(options: [.alert, .sound])
        }
        return settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
    }

    func notify(amigo: Amigo, message: ChatMessage) async {
        let center = UNUserNotificationCenter.current()
        do {
            let settings = await center.notificationSettings()
            guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else { return }
            let content = UNMutableNotificationContent()
            content.title = amigo.name
            content.body = message.text
            content.sound = .default
            content.threadIdentifier = "chat:\(amigo.id)"
            content.userInfo = ["amigoID": amigo.id]
            try await center.add(UNNotificationRequest(identifier: message.id.uuidString, content: content, trigger: nil))
            deliveryError = nil
        } catch {
            deliveryError = "Your message arrived in Chats, but its notification could not be displayed: \(error.localizedDescription)"
        }
    }
}
