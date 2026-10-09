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

    @Test("Recovery saves one exchange and charges Role Play once")
    func recoveredReplyCommitsOnce() async throws {
        let generated = GeneratedAmigoReply(spanish: "¡Hola! ¿Qué quieres tomar?", english: "Hi! What would you like to drink?", profileFacts: [])
        let generator = ScriptedAmigoGenerator([.failure(.structuredOutput), .success(generated)])
        let repository = MemoryConversationRepository(archive: PracticeArchive())
        let manager = ConversationManager(repository: repository, responder: OnDeviceSpanishChat(generator: generator))
        await manager.loadSavedPractice()
        let context = ChatContext(amigo: friend.amigo, scenario: RolePlayScenario.catalogue[0])
        #expect(manager.authorizeRolePlay(context))
        try await manager.send("Can I have coffee?", in: context)
        #expect(await generator.calls == 2)
        #expect(manager.doubloons == 8)
        #expect(manager.conversation(for: context).messages.count == 2)
        #expect(await repository.savedArchive()?.doubloons == 8)
    }

    @Test("Recovery at the first reward threshold counts only one successful exchange")
    func recoveredReplyEarnsOnce() async throws {
        let generated = GeneratedAmigoReply(spanish: "¡Hola!", english: "Hello!", profileFacts: [])
        let outcomes: [Result<GeneratedAmigoReply, OnDeviceChatError>] = Array(repeating: .success(generated), count: 9) + [.failure(.structuredOutput), .success(generated)]
        let generator = ScriptedAmigoGenerator(outcomes)
        let repository = MemoryConversationRepository(archive: PracticeArchive())
        let manager = ConversationManager(repository: repository, responder: OnDeviceSpanishChat(generator: generator), currentDate: { today })
        await manager.loadSavedPractice()
        for _ in 0..<10 { try await manager.send("Hola", in: friend) }
        #expect(await generator.calls == 11)
        #expect(manager.doubloons == 11)
        #expect(await repository.savedArchive()?.dailyAmigoChatProgress?[friend.amigo.id]?.successfulExchanges == 10)
        #expect(manager.conversation(for: friend).messages.filter { $0.role == .learner }.count == 10)
    }

    @Test("Alma welcomes once, then Nico arrives after the first earned doubloon")
    func messagingOnboarding() async throws {
        let repository = MemoryConversationRepository(archive: PracticeArchive())
        let notifications = RecordingAmigoNotifications()
        let manager = ConversationManager(repository: repository, responder: StubSpanishChat(reply: .success("Hola")), notifications: notifications)
        await manager.loadSavedPractice()
        try await manager.introduceFirstAmigo()
        try await manager.introduceFirstAmigo()
        #expect(notifications.amigoIDs == ["alma"])
        #expect(manager.conversation(for: friend).messages.count == 1)
        #expect(manager.doubloons == 10)
        try await manager.send("Me llamo Matt", in: friend)
        #expect(notifications.amigoIDs == ["alma"])
        #expect(notifications.permissionRequests == 0)
        for _ in 0..<9 { try await manager.send("Hola", in: friend) }
        #expect(manager.doubloons == 11)
        #expect(manager.conversation(for: friend).messages.last?.text == AmigoWelcome.doubloonExplanation.spanish)
        #expect(notifications.amigoIDs == ["alma", "nico"])
        #expect(await repository.savedArchive()?.introducedAmigoIDs == ["alma", "nico"])
        try await manager.send("Hola otra vez", in: friend)
        #expect(notifications.amigoIDs == ["alma", "nico"])
    }

    @Test("Notification choice advances through Sol without automatically introducing Tavo", arguments: [true, false])
    func notificationChoiceAndRemainingIntroductions(enable: Bool) async throws {
        var archive = PracticeArchive()
        archive.introducedAmigoIDs = ["alma", "nico"]
        let repository = MemoryConversationRepository(archive: archive)
        let notifications = RecordingAmigoNotifications()
        let manager = ConversationManager(repository: repository, responder: StubSpanishChat(reply: .success("Hola")), notifications: notifications)
        await manager.loadSavedPractice()
        let nico = ChatContext(amigo: Amigo.catalogue[1], scenario: nil)
        #expect(manager.offersNotificationPermission(in: nico))
        try await manager.send("Hola", in: nico)
        #expect(notifications.amigoIDs.isEmpty)
        try await manager.answerNotificationInvitation(enable: enable)
        try await manager.answerNotificationInvitation(enable: enable)
        #expect(notifications.permissionRequests == (enable ? 1 : 0))
        #expect(notifications.amigoIDs == ["ines"])
        #expect(!manager.offersNotificationPermission(in: nico))
        for amigo in Amigo.catalogue where ["ines", "dani", "lucia", "rafa", "sol"].contains(amigo.id) {
            try await manager.send("Hola", in: ChatContext(amigo: amigo, scenario: nil))
        }
        #expect(notifications.amigoIDs == ["ines", "dani", "lucia", "rafa", "sol"])
        #expect(await repository.savedArchive()?.introducedAmigoIDs?.contains("tavo") == false)
    }

    @Test("Denied permission still introduces Inés, and failed saves leave the choice retryable")
    func deniedNotificationPermissionAndSaveRetry() async throws {
        var archive = PracticeArchive()
        archive.introducedAmigoIDs = ["alma", "nico"]
        let repository = MemoryConversationRepository(archive: archive)
        let notifications = RecordingAmigoNotifications()
        notifications.permissionGranted = false
        let manager = ConversationManager(repository: repository, responder: StubSpanishChat(reply: .success("Hola")), notifications: notifications)
        await manager.loadSavedPractice()
        let nico = ChatContext(amigo: Amigo.catalogue[1], scenario: nil)
        await repository.failNextSave()
        await #expect(throws: TestFailure.self) { try await manager.answerNotificationInvitation(enable: true) }
        #expect(manager.offersNotificationPermission(in: nico))
        #expect(notifications.amigoIDs.isEmpty)
        try await manager.answerNotificationInvitation(enable: true)
        #expect(notifications.amigoIDs == ["ines"])
        #expect(manager.conversation(for: nico).messages.last?.englishText?.contains("No problem") == true)
    }

    @Test("A referral shared in chat is saved in the editable profile")
    func referralSource() async throws {
        let profiles = ProfileManager(repository: MemoryProfileRepository())
        await profiles.loadSavedProfile()
        let responder = ProfileAwareSpanishChat(facts: [ProfileFact(field: .referralSource, value: "Instagram", evidence: "Instagram")])
        let manager = ConversationManager(repository: MemoryConversationRepository(archive: PracticeArchive()), responder: responder, profileFeature: profiles)
        await manager.loadSavedPractice()
        try await manager.send("Instagram", in: ChatContext(amigo: Amigo.catalogue[2], scenario: nil))
        #expect(profiles.profile.value(for: .referralSource) == "Instagram")
    }

    @Test("A failed welcome save sends no notification and retry does not duplicate it")
    func failedWelcome() async throws {
        let repository = MemoryConversationRepository(archive: PracticeArchive())
        let notifications = RecordingAmigoNotifications()
        let manager = ConversationManager(repository: repository, responder: StubSpanishChat(reply: .success("Hola")), notifications: notifications)
        await manager.loadSavedPractice()
        await repository.failNextSave()
        await #expect(throws: TestFailure.self) { try await manager.introduceFirstAmigo() }
        #expect(notifications.amigoIDs.isEmpty)
        #expect(manager.conversation(for: friend).messages.isEmpty)
        try await manager.introduceFirstAmigo()
        #expect(notifications.amigoIDs == ["alma"])
    }

    @Test("Chat facts update the shared profile while role-play facts do not")
    func conversationalProfile() async throws {
        let profiles = ProfileManager(repository: MemoryProfileRepository())
        await profiles.loadSavedProfile()
        let responder = ProfileAwareSpanishChat(facts: [ProfileFact(field: .firstName, value: "Matt", evidence: "Matt")])
        let manager = ConversationManager(repository: MemoryConversationRepository(archive: PracticeArchive()), responder: responder, profileFeature: profiles)
        await manager.loadSavedPractice()
        let rolePlay = ChatContext(amigo: friend.amigo, scenario: RolePlayScenario.catalogue[0])
        #expect(manager.authorizeRolePlay(rolePlay))
        try await manager.send("Me llamo Matt", in: rolePlay)
        #expect(profiles.profile.value(for: .firstName).isEmpty)
        try await manager.send("Me llamo Matt", in: friend)
        #expect(profiles.profile.value(for: .firstName) == "Matt")
        #expect(manager.profileNotice != nil)
        try await manager.send("Hola Matt", in: friend)
        #expect(await responder.receivedProfile?.value(for: .firstName) == "Matt")
    }

    @Test("A profile write failure does not undo or duplicate a successful chat reply")
    func profileWriteFailureKeepsReply() async throws {
        let repository = MemoryProfileRepository()
        let profiles = ProfileManager(repository: repository)
        await profiles.loadSavedProfile()
        let responder = ProfileAwareSpanishChat(facts: [ProfileFact(field: .firstName, value: "Matt", evidence: "Matt")])
        let manager = ConversationManager(repository: MemoryConversationRepository(archive: PracticeArchive()), responder: responder, profileFeature: profiles)
        await manager.loadSavedPractice()
        await repository.failNextSave()
        try await manager.send("Matt", in: friend)
        #expect(manager.conversation(for: friend).messages.count == 2)
        #expect(profiles.profile.value(for: .firstName).isEmpty)
        #expect(manager.profileNotice?.contains("could not be updated") == true)
    }

    @Test("Suggested greetings persist once per day without rewards or learner messages")
    func suggestedGreeting() async throws {
        let (manager, repository) = await makeManager()
        let context = ChatContext(amigo: friend.amigo, scenario: nil, startsWithGreeting: true)
        try await manager.send("Hola", in: friend)
        try await manager.startSuggestedChat(context)
        try await manager.startSuggestedChat(context)
        let messages = manager.conversation(for: context).messages
        #expect(messages.count == 3)
        #expect(messages.last?.role == .storyteller)
        #expect(messages.last?.englishText == "Hello")
        #expect(messages.last?.startsNewConversation == true)
        #expect(manager.doubloons == 10)
        #expect(await repository.savedArchive()?.dailyAmigoChatProgress?[friend.amigo.id]?.successfulExchanges == 1)
        let reloaded = ConversationManager(repository: repository, responder: StubSpanishChat(reply: .success("Hola")), currentDate: { today })
        await reloaded.loadSavedPractice()
        try await reloaded.startSuggestedChat(context)
        #expect(reloaded.conversation(for: context).messages.count == 3)
    }

    @Test("A failed greeting save leaves the feed unchanged and can be retried")
    func greetingSaveFailure() async throws {
        let (manager, repository) = await makeManager()
        let context = ChatContext(amigo: friend.amigo, scenario: nil, startsWithGreeting: true)
        await repository.failNextSave()
        await #expect(throws: TestFailure.self) { try await manager.startSuggestedChat(context) }
        #expect(manager.conversation(for: context).messages.isEmpty)
        try await manager.startSuggestedChat(context)
        #expect(manager.conversation(for: context).messages.count == 1)
        #expect(manager.conversation(for: context).messages.first?.startsNewConversation == false)
    }

    @Test("Daily suggestions cycle through eight different amigos")
    func dailySuggestionRotation() async throws {
        var date = today
        let manager = ConversationManager(repository: MemoryConversationRepository(archive: PracticeArchive()), responder: StubSpanishChat(reply: .success("Hola")), currentDate: { date })
        await manager.loadSavedPractice()
        var suggestedIDs: Set<String> = []
        for _ in 0..<8 {
            for _ in 0..<10 { try await manager.send("Hola", in: friend) }
            manager.prepareStreakLaunch()
            let invitation = try #require(manager.dailyAmigoInvitation)
            suggestedIDs.insert(invitation.amigo.id)
            manager.prepareStreakLaunch()
            #expect(manager.dailyAmigoInvitation?.amigo.id == invitation.amigo.id)
            date = date.addingTimeInterval(86_400)
        }
        #expect(suggestedIDs.count == 8)
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

    @Test("The saved join date is retained when loading practice")
    func savedJoinDate() async {
        let earlier = today.addingTimeInterval(-3 * 86_400)
        var archive = PracticeArchive()
        archive.firstOpenedAt = earlier
        let (manager, repository) = await makeManager(archive: archive)
        #expect(manager.daysSinceFirstUse == 3)
        #expect(await repository.savedArchive()?.firstOpenedAt == earlier)
    }

    @Test("Saved practice days are retained when loading practice")
    func savedPracticeDays() async {
        var archive = PracticeArchive()
        archive.practiceDays = ["2026-05-20"]
        let (manager, repository) = await makeManager(archive: archive)
        #expect(manager.daysSinceFirstUse == 0)
        #expect(await repository.savedArchive()?.practiceDays == ["2026-05-20"])
    }

    @Test("A continuing streak offers an Amigo whenever a streak launch is prepared")
    func continuingStreakOffersDailyAmigo() async throws {
        var archive = PracticeArchive()
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        archive.practiceDays = [formatter.string(from: today)]
        archive.streakTimeZoneIdentifier = TimeZone.current.identifier

        let repository = MemoryConversationRepository(archive: archive)
        let manager = ConversationManager(
            repository: repository,
            responder: StubSpanishChat(reply: .success("Hola")),
            currentDate: { today }
        )
        await manager.loadSavedPractice()

        #expect(manager.launchStreak == 1)
        #expect(manager.hasCompletedDayStreak)
        let invitation = try #require(manager.dailyAmigoInvitation)
        #expect(invitation.streak == 1)
        #expect(Amigo.catalogue.contains(invitation.amigo))

        manager.prepareStreakLaunch()
        #expect(manager.launchStreak == 1)
        #expect(manager.dailyAmigoInvitation != nil)
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
