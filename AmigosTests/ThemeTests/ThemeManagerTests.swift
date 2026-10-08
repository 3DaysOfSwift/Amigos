import Foundation
import Testing
@testable import Amigos

@Suite("Colour theme")
@MainActor
struct ThemeManagerTests {
    @Test("The selected theme survives a new manager instance")
    func persistsSelection() throws {
        let suiteName = "AmigosThemeTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let first = ThemeManager(defaults: defaults)
        #expect(first.currentTheme == .midnight)
        #expect(first.currentWallpaper == .amigos)
        first.currentTheme = .daylight
        first.currentWallpaper = .study
        let next = ThemeManager(defaults: defaults)
        #expect(next.currentTheme == .daylight)
        #expect(next.currentWallpaper == .study)
    }

    @Test("All seven themes are available with both appearances")
    func completeThemeSelection() {
        #expect(AppColourTheme.allCases.count == 7)
        #expect(Set(AppColourTheme.allCases.map(\.name)).count == 7)
        #expect(AppColourTheme.allCases.filter { $0.colourScheme == .dark }.count == 4)
        #expect(AppColourTheme.allCases.filter { $0.colourScheme == .light }.count == 3)
    }

    @Test("Obsolete selections fall back to the branded defaults")
    func obsoleteSelectionFallback() throws {
        let suiteName = "AmigosThemeFallbackTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set("missing-theme", forKey: "amigos.selectedColourTheme")
        defaults.set("missing-wallpaper", forKey: "amigos.selectedChatWallpaper")

        let manager = ThemeManager(defaults: defaults)
        #expect(manager.currentTheme == .midnight)
        #expect(manager.currentWallpaper == .amigos)
    }

    @Test("A selected HolaTalk theme is migrated to the Amigos preference key")
    func migratesLegacyThemeSelection() throws {
        let suiteName = "AmigosThemeMigrationTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set(AppColourTheme.daylight.rawValue, forKey: "holaTalk.selectedColourTheme")

        let manager = ThemeManager(defaults: defaults)

        #expect(manager.currentTheme == .daylight)
        #expect(defaults.string(forKey: "amigos.selectedColourTheme") == AppColourTheme.daylight.rawValue)
    }
}
