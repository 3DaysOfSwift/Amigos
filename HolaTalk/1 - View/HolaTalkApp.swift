import SwiftUI

@main
struct HolaTalkApp: App {
    @UIApplicationDelegateAdaptor(HolaTalkAppDelegate.self) private var appDelegate
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

final class HolaTalkAppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        Task { await AppModel.shared.applicationDidFinishLaunching() }
        return true
    }
}
