import Testing
@testable import Amigos

@Suite("Practice progress screen")
@MainActor
struct PracticeProgressViewModelTests {
    @Test("Progress reflects the shared conversation feature")
    func showsPracticeProgress() async {
        let manager = await makeTestConversationManager()
        let viewModel = PracticeProgressViewModel(conversations: manager)
        #expect(viewModel.currentStreak == manager.currentStreak)
        #expect(viewModel.streakDescription == "0 days")
        #expect(viewModel.currentWeek.count == 7)
        #expect(viewModel.doubloons == manager.doubloons)
        #expect(viewModel.daysSinceFirstUse == manager.daysSinceFirstUse)
    }
}
