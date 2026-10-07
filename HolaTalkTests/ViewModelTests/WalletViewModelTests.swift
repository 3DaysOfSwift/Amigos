import Testing
@testable import HolaTalk

@Suite("Wallet screen")
@MainActor
struct WalletViewModelTests {
    @Test("The balance reflects a confirmed chat payment")
    func reflectsPayment() async throws {
        let manager = await makeTestConversationManager()
        let viewModel = WalletViewModel(conversations: manager)
        let context = ChatContext(amigo: Amigo.catalogue[0], scenario: nil)
        try await manager.send("Hola", in: context)
        #expect(viewModel.doubloons == 9)
    }
}
