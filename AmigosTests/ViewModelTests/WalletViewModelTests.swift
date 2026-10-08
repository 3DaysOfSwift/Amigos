import Testing
@testable import Amigos

@Suite("Wallet screen")
@MainActor
struct WalletViewModelTests {
    @Test("The balance reflects a reward after ten Amigo exchanges")
    func reflectsReward() async throws {
        let manager = await makeTestConversationManager()
        let viewModel = WalletViewModel(conversations: manager)
        let context = ChatContext(amigo: Amigo.catalogue[0], scenario: nil)
        for _ in 0..<10 { try await manager.send("Hola", in: context) }
        #expect(viewModel.doubloons == 11)
    }
}
