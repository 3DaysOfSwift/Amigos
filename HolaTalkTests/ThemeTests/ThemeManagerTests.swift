import Foundation
import Testing
@testable import HolaTalk

@Suite("Colour theme")
@MainActor
struct ThemeManagerTests {
    @Test("The selected theme survives a new manager instance")
    func persistsSelection() throws {
        let suiteName = "HolaTalkThemeTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let first = ThemeManager(defaults: defaults)
        #expect(first.currentTheme == .midnight)
        first.currentTheme = .daylight
        let next = ThemeManager(defaults: defaults)
        #expect(next.currentTheme == .daylight)
    }
}
