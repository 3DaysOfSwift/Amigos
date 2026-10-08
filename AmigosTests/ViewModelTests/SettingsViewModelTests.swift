import Testing
@testable import Amigos

@Suite("Settings screen")
@MainActor
struct SettingsViewModelTests {
    @Test("The version text includes a version and build number")
    func versionInformation() {
        let viewModel = SettingsViewModel(profileFeature: ProfileManager(repository: MemoryProfileRepository()))
        #expect(viewModel.appVersion.contains("Version"))
        #expect(viewModel.appVersion.contains("("))
    }

    @Test("Settings reflects the saved learner name")
    func profileName() async throws {
        let profile = ProfileManager(repository: MemoryProfileRepository())
        await profile.loadSavedProfile()
        try await profile.saveDisplayName("Sam")
        let viewModel = SettingsViewModel(profileFeature: profile)
        #expect(viewModel.displayName == "Sam")
    }
}
