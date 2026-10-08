import Testing
@testable import Amigos

@Suite("Role Play screen")
@MainActor
struct RolePlayViewModelTests {
    @Test("The screen shows the first scenario unlocked and later ones locked")
    func presentsProgression() async {
        let manager = await makeTestConversationManager()
        let viewModel = RolePlayViewModel(conversations: manager)
        #expect(viewModel.options.count == RolePlayScenario.catalogue.count)
        #expect(viewModel.options[0].isUnlocked)
        #expect(!viewModel.options[1].isUnlocked)
    }
}
