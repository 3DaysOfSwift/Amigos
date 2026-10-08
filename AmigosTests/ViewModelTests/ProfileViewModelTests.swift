import Testing
@testable import Amigos

@Suite("Profile screen")
@MainActor
struct ProfileViewModelTests {
    @Test("Saving a name updates the profile and confirms success")
    func saveName() async {
        let manager = ProfileManager(repository: MemoryProfileRepository())
        await manager.loadSavedProfile()
        let viewModel = ProfileViewModel(profileFeature: manager)
        viewModel.draftName = "  Sam  "
        await viewModel.save()
        #expect(viewModel.didSave)
        #expect(viewModel.draftName == "Sam")
        #expect(manager.profile.displayName == "Sam")
    }

    @Test("A failed save leaves the draft available to correct")
    func retainDraftOnFailure() async {
        let manager = ProfileManager(repository: MemoryProfileRepository())
        await manager.loadSavedProfile()
        let viewModel = ProfileViewModel(profileFeature: manager)
        viewModel.draftName = " "
        await viewModel.save()
        #expect(viewModel.error != nil)
        #expect(viewModel.draftName == " ")
        #expect(!viewModel.didSave)
    }
}
