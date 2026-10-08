import Foundation
import Observation

@MainActor
@Observable
final class ThemeManager {
    static let shared = ThemeManager()
    private let selectedColourThemeStorageKey = "holaTalk.selectedColourTheme"
    private let selectedChatWallpaperStorageKey = "amigos.selectedChatWallpaper"
    private let defaults: UserDefaults

    var currentTheme: AppColourTheme {
        didSet { defaults.set(currentTheme.rawValue, forKey: selectedColourThemeStorageKey) }
    }

    var currentWallpaper: ChatWallpaper {
        didSet { defaults.set(currentWallpaper.rawValue, forKey: selectedChatWallpaperStorageKey) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        currentTheme = AppColourTheme(rawValue: defaults.string(forKey: selectedColourThemeStorageKey) ?? "") ?? .midnight
        currentWallpaper = ChatWallpaper(rawValue: defaults.string(forKey: selectedChatWallpaperStorageKey) ?? "") ?? .amigos
    }
}
