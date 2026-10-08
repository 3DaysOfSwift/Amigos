import Foundation
import Testing
@testable import Amigos

@Suite("Conversation feature")
@MainActor
struct ConversationManagerTests {
    private let today = Date(timeIntervalSince1970: 1_780_000_000)

    private var friend: ChatContext {
        ChatContext(amigo: Amigo.catalogue[0], scenario: nil)
    }

    private func makeManager(
        archive: PracticeArchive = PracticeArchive(),
        reply: Result<String, Error> = .success("¡Hola! ¿Cómo estás?")
    ) async -> (ConversationManager, MemoryConversationRepository) {
        let repository = MemoryConversationRepository(archive: archive)
        let manager = ConversationManager(repository: repository, responder: StubSpanishChat(reply: reply), currentDate: { today })
        await manager.loadSavedPractice()
        return (manager, repository)
    }

    @Test("Amigos have distinct conversations")
    func amigoCatalogue() async {
        let ids = Amigo.catalogue.map(\.id)
        #expect(ids.count == 8)
        #expect(Set(ids).count == ids.count)
        #expect(Set(Amigo.catalogue.map(\.name)).count == ids.count)
        #expect(Set(Amigo.catalogue.map { ChatContext(amigo: $0, scenario: nil).id }).count == ids.count)
    }

    @Test("Searching amigos is case-insensitive and a blank query returns everyone")
    func amigoSearch() async {
        let (manager, _) = await makeManager()
        #expect(manager.amigos(matching: " INÉS ").map(\.id) == ["ines"])
        #expect(manager.amigos(matching: " LUCÍA ").map(\.id) == ["lucia"])
        #expect(manager.amigos(matching: " ").count == manager.amigos.count)
    }

    @Test("An active paid conversation remains available for ten minutes")
    func paidSessionWindow() {
        let active = Conversation(paidAt: today.addingTimeInterval(-599))
        let expired = Conversation(paidAt: today.addingTimeInterval(-601))
        #expect(active.canContinue(until: today))
        #expect(!expired.canContinue(until: today))
        #expect(!Conversation(paidAt: today, finished: true).canContinue(until: today))
    }

    @Test("First opening is saved and the elapsed day count uses calendar days")
    func firstOpeningIsSaved() async {
        let repository = MemoryConversationRepository(archive: nil)
        let manager = ConversationManager(repository: repository,
                                          responder: StubSpanishChat(reply: .success("Hola")),
                                          currentDate: { today })
        await manager.loadSavedPractice()
        #expect(manager.isLoaded)
        #expect(manager.daysSinceFirstUse == 0)
        #expect(await repository.savedArchive()?.firstOpenedAt == today)
    }

    @Test("A failed first-opening save does not pretend practice loaded")
    func failedFirstOpeningSave() async {
        let repository = MemoryConversationRepository(archive: nil)
        await repository.failNextSave()
        let manager = ConversationManager(repository: repository,
                                          responder: StubSpanishChat(reply: .success("Hola")),
                                          currentDate: { today })
        await manager.loadSavedPractice()
        #expect(!manager.isLoaded)
        #expect(manager.loadError != nil)
        #expect(await repository.savedArchive()?.doubloons == nil)
    }

    @Test("Older saved conversations establish the earliest known start date")
    func olderArchiveStartDate() async {
        let earlier = today.addingTimeInterval(-3 * 86_400)
        var archive = PracticeArchive()
        archive.conversations[friend.id] = Conversation(paidAt: earlier)
        let (manager, repository) = await makeManager(archive: archive)
        #expect(manager.daysSinceFirstUse == 3)
        #expect(await repository.savedArchive()?.firstOpenedAt == earlier)
    }

    @Test("Older practice days are retained when establishing the earliest known start")
    func olderPracticeDayStartDate() async {
        var archive = PracticeArchive()
        archive.practiceDays = ["2026-05-20"]
        let (manager, repository) = await makeManager(archive: archive)
        #expect(manager.daysSinceFirstUse > 0)
        #expect(await repository.savedArchive()?.practiceDays == ["2026-05-20"])
    }

    @Test("Friend chats are free and the first two exchanges do not earn a doubloon")
    func successfulReply() async throws {
        let (manager, repository) = await makeManager()
        try await manager.send("Hola", in: friend)
        #expect(manager.doubloons == 10)
        #expect(manager.conversation(for: friend).messages.count == 2)
        try await manager.send("Bien", in: friend)
        #expect(manager.doubloons == 10)
        #expect(manager.conversation(for: friend).messages.count == 4)
        #expect(await repository.savedArchive()?.conversations[friend.id]?.messages.count == 4)
    }

    @Test("Failed AI reply preserves the draft's underlying conversation and balance")
    func failedReplyDoesNotCharge() async {
        let (manager, repository) = await makeManager(reply: .failure(TestFailure.unavailable))
        await #expect(throws: TestFailure.self) { try await manager.send("Hola", in: friend) }
        #expect(manager.doubloons == 10)
        #expect(manager.conversation(for: friend).messages.isEmpty)
        #expect(await repository.savedArchive()?.doubloons == 10)
        #expect(await repository.savedArchive()?.conversations.isEmpty == true)
    }

    @Test("An AI response saves its English counterpart with the Spanish message")
    func responsePersistsEnglishCounterpart() async throws {
        let (manager, _) = await makeManager()
        try await manager.send("Hola", in: friend)
        let reply = try #require(manager.conversation(for: friend).messages.last)
        #expect(reply.text == "¡Hola! ¿Cómo estás?")
        #expect(reply.englishText == "Hello")
    }

    @Test("Failed save does not publish a successful exchange")
    func failedSaveDoesNotPublish() async {
        let (manager, repository) = await makeManager()
        await repository.failNextSave()
        await #expect(throws: TestFailure.self) { try await manager.send("Hola", in: friend) }
        #expect(manager.doubloons == 10)
        #expect(manager.conversation(for: friend).messages.isEmpty)
    }

    @Test("Each Amigo earns after ten exchanges, independently each day")
    func dailyReward() async throws {
        var date = today
        let manager = ConversationManager(repository: MemoryConversationRepository(archive: PracticeArchive()),
                                          responder: StubSpanishChat(reply: .success("Hola")), currentDate: { date })
        await manager.loadSavedPractice()
        for _ in 0..<9 { try await manager.send("Hola", in: friend) }
        #expect(manager.doubloons == 10)
        try await manager.send("Diez", in: friend)
        #expect(manager.doubloons == 11)
        let nico = ChatContext(amigo: Amigo.catalogue[1], scenario: nil)
        for _ in 0..<10 { try await manager.send("Hola", in: nico) }
        #expect(manager.doubloons == 12)
        date = today.addingTimeInterval(86_400)
        for _ in 0..<10 { try await manager.send("Buenos días", in: friend) }
        #expect(manager.doubloons == 13)
    }

    @Test("Further rewards require forty additional exchanges with the same Amigo")
    func repeatReward() async throws {
        let (manager, repository) = await makeManager()
        for _ in 0..<49 { try await manager.send("Hola", in: friend) }
        #expect(manager.doubloons == 11)
        #expect(await repository.savedArchive()?.dailyAmigoChatProgress?[friend.amigo.id]?.successfulExchanges == 49)
        try await manager.send("Cincuenta", in: friend)
        #expect(manager.doubloons == 12)
        for _ in 0..<39 { try await manager.send("Hola", in: friend) }
        #expect(manager.doubloons == 12)
        try await manager.send("Noventa", in: friend)
        #expect(manager.doubloons == 13)
    }

    @Test("An unsaved tenth exchange neither advances progress nor pays a doubloon")
    func failedTenthExchange() async throws {
        let (manager, repository) = await makeManager()
        for _ in 0..<9 { try await manager.send("Hola", in: friend) }
        await repository.failNextSave()
        await #expect(throws: TestFailure.self) { try await manager.send("Diez", in: friend) }
        #expect(manager.doubloons == 10)
        #expect(manager.conversation(for: friend).messages.count == 18)
        #expect(await repository.savedArchive()?.dailyAmigoChatProgress?[friend.amigo.id]?.successfulExchanges == 9)
        try await manager.send("Diez", in: friend)
        #expect(manager.doubloons == 11)
    }

    @Test("Role Play requires a slide and never earns a chat reward")
    func rolePlayAdmission() async throws {
        let context = ChatContext(amigo: Amigo.catalogue[0], scenario: RolePlayScenario.catalogue[0])
        let (manager, repository) = await makeManager()
        #expect(!manager.canStart(context))
        await #expect(throws: ConversationError.self) {
            try await manager.send("Un café", in: context)
        }
        #expect(await repository.savedArchive()?.doubloons == 10)
        #expect(manager.authorizeRolePlay(context))
        #expect(manager.canStart(context))
        try await manager.send("Un café", in: context)
        #expect(manager.doubloons == 8)
        try await manager.send("Gracias", in: context)
        #expect(manager.doubloons == 8)
    }

    @Test("Failed Role Play reply does not charge and keeps admission ready for retry")
    func failedRolePlayReply() async {
        let context = ChatContext(amigo: Amigo.catalogue[0], scenario: RolePlayScenario.catalogue[0])
        let (manager, _) = await makeManager(reply: .failure(TestFailure.unavailable))
        #expect(manager.authorizeRolePlay(context))
        await #expect(throws: TestFailure.self) { try await manager.send("Un café", in: context) }
        #expect(manager.doubloons == 10)
        #expect(manager.canStart(context))
    }

    @Test("A low balance cannot authorize Role Play, but friend chats can still earn")
    func lowBalance() async throws {
        let context = ChatContext(amigo: Amigo.catalogue[0], scenario: RolePlayScenario.catalogue[0])
        let (manager, _) = await makeManager(archive: PracticeArchive(doubloons: 1))
        #expect(!manager.authorizeRolePlay(context))
        for _ in 0..<10 { try await manager.send("Hola", in: friend) }
        #expect(manager.doubloons == 2)
        #expect(manager.authorizeRolePlay(context))
    }

    @Test("An Amigo reward remains claimed after reloading saved practice")
    func rewardPersists() async throws {
        let (manager, repository) = await makeManager()
        for _ in 0..<10 { try await manager.send("Hola", in: friend) }
        let reloaded = ConversationManager(repository: repository,
                                           responder: StubSpanishChat(reply: .success("Hola")), currentDate: { today })
        await reloaded.loadSavedPractice()
        try await reloaded.send("Otra vez", in: friend)
        #expect(reloaded.doubloons == 11)
    }

    @Test("An earlier one-exchange reward is preserved without paying again at ten")
    func legacyReward() async throws {
        var archive = PracticeArchive(doubloons: 11)
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyy-MM-dd"
        archive.rewardedAmigoDays = [friend.amigo.id: formatter.string(from: today)]
        let (manager, _) = await makeManager(archive: archive)
        for _ in 0..<9 { try await manager.send("Hola", in: friend) }
        #expect(manager.doubloons == 11)
    }

    @Test("Role plays unlock in order after three exchanges")
    func rolePlayProgression() async throws {
        let context = ChatContext(amigo: Amigo.catalogue[0], scenario: RolePlayScenario.catalogue[0])
        let (manager, _) = await makeManager()
        #expect(manager.isRolePlayUnlocked(0))
        #expect(!manager.isRolePlayUnlocked(1))
        #expect(manager.authorizeRolePlay(context))
        for _ in 0..<3 { try await manager.send("Un café, por favor", in: context) }
        #expect(manager.doubloons == 8)
        try await manager.finishRolePlay(context)
        #expect(manager.isRolePlayUnlocked(1))
        #expect(manager.rolePlayCount(RolePlayScenario.catalogue[0]) == 1)
        #expect(manager.conversation(for: context).finished)
    }

    @Test("Unreadable saved practice is reported rather than replaced")
    func loadFailure() async {
        let repository = MemoryConversationRepository(archive: nil)
        await repository.failLoad()
        let manager = ConversationManager(repository: repository, responder: StubSpanishChat(reply: .success("Hola")))
        await manager.loadSavedPractice()
        #expect(!manager.isLoaded)
        #expect(manager.loadError != nil)
    }

    @Test("Overlapping sends cannot charge or publish a second exchange")
    func overlappingSends() async throws {
        let responder = SuspendedSpanishChat()
        let manager = ConversationManager(
            repository: MemoryConversationRepository(archive: PracticeArchive()),
            responder: responder,
            currentDate: { today }
        )
        await manager.loadSavedPractice()
        let first = Task { try await manager.send("Hola", in: friend) }
        await responder.waitUntilStarted()
        await #expect(throws: ConversationError.self) {
            try await manager.send("Otra", in: friend)
        }
        await responder.complete(with: "¡Hola!")
        try await first.value
        #expect(manager.doubloons == 10)
        #expect(manager.conversation(for: friend).messages.count == 2)
    }

    @Test("Cancellation before an AI reply leaves saved practice untouched")
    func cancelledReply() async {
        let responder = SuspendedSpanishChat()
        let manager = ConversationManager(
            repository: MemoryConversationRepository(archive: PracticeArchive()),
            responder: responder,
            currentDate: { today }
        )
        await manager.loadSavedPractice()
        let pending = Task { try await manager.send("Hola", in: friend) }
        await responder.waitUntilStarted()
        pending.cancel()
        await responder.complete(with: "¡Hola!")
        await #expect(throws: CancellationError.self) { try await pending.value }
        #expect(manager.doubloons == 10)
        #expect(manager.conversation(for: friend).messages.isEmpty)
    }
}
