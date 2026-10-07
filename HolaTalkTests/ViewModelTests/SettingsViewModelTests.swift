import Testing
@testable import HolaTalk

@Suite("Settings screen")
@MainActor
struct SettingsViewModelTests {
    @Test("The version text includes a version and build number")
    func versionInformation() {
        let viewModel = SettingsViewModel()
        #expect(viewModel.appVersion.contains("Version"))
        #expect(viewModel.appVersion.contains("("))
    }
}
