import Foundation
import Observation

@MainActor
@Observable
final class ThemeManager {
    static let shared = ThemeManager()
    private let selectedColourThemeStorageKey = "amigos.selectedColourTheme"
    private let legacySelectedColourThemeStorageKey = "holaTalk.selectedColourTheme"
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
        let selectedThemeIdentifier = defaults.string(forKey: selectedColourThemeStorageKey)
            ?? defaults.string(forKey: legacySelectedColourThemeStorageKey)
        currentTheme = AppColourTheme(rawValue: selectedThemeIdentifier ?? "") ?? .midnight
        currentWallpaper = ChatWallpaper(rawValue: defaults.string(forKey: selectedChatWallpaperStorageKey) ?? "") ?? .amigos

        if defaults.string(forKey: selectedColourThemeStorageKey) == nil,
           let legacyThemeIdentifier = defaults.string(forKey: legacySelectedColourThemeStorageKey) {
            defaults.set(legacyThemeIdentifier, forKey: selectedColourThemeStorageKey)
        }
    }
}
