import SwiftUI

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

final class AmigosAppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        Task { await AppModel.shared.applicationDidFinishLaunching() }
        return true
    }
}
