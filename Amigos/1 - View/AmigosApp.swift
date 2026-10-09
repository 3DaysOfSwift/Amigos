import SwiftUI
import UserNotifications

@main
struct AmigosApp: App {
    @UIApplicationDelegateAdaptor(AmigosAppDelegate.self) private var appDelegate
    @State private var themeManager = ThemeManager.shared

    var body: some Scene {
        WindowGroup {
            AppEntryView()
                .environment(themeManager)
                .tint(themeManager.currentTheme.palette.accent)
                .preferredColorScheme(themeManager.currentTheme.colourScheme)
        }
    }
}

final class AmigosAppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        Task { await AppModel.shared.applicationDidFinishLaunching() }
        return true
    }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .list]
    }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        guard let amigoID = response.notification.request.content.userInfo["amigoID"] as? String else { return }
        await MainActor.run {
            AppModel.shared.messageNotificationsManager.pendingAmigoID = amigoID
        }
    }
}
