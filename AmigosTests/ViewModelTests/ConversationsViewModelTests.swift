import Foundation
import Testing
@testable import Amigos

@Suite("Conversations screen")
@MainActor
struct ConversationsViewModelTests {
    @Test("The daily countdown follows the closest amigo and completes after ten exchanges")
    func dailyCountdown() async throws {
        let manager = await makeTestConversationManager()
        let viewModel = ConversationsViewModel(conversations: manager)
        let alma = ChatContext(amigo: Amigo.catalogue[0], scenario: nil)
        let nico = ChatContext(amigo: Amigo.catalogue[1], scenario: nil)
        #expect(viewModel.streakStatusDescription == "10 messages required")
        try await manager.send("Hola", in: alma)
        #expect(viewModel.streakStatusDescription == "9 messages required")
        try await manager.send("Hola", in: nico)
        #expect(viewModel.streakStatusDescription == "9 messages required")
        for _ in 0..<8 { try await manager.send("Hola", in: alma) }
        #expect(viewModel.streakStatusDescription == "1 message required")
        try await manager.send("Hola", in: alma)
        #expect(viewModel.streakStatusDescription == "Complete")
        #expect(manager.messagesRemainingForDayStreak == 0)
    }

    @Test("Yesterday's progress does not reduce today's countdown")
    func countdownResetsForNewDay() async {
        var archive = PracticeArchive()
        archive.dailyAmigoChatProgress = ["alma": DailyAmigoChatProgress(day: "2000-01-01", successfulExchanges: 9, awardedDoubloons: 0)]
        let manager = await makeTestConversationManager(archive: archive)
        #expect(manager.messagesRemainingForDayStreak == 10)
    }

    @Test("Failed replies do not reduce the countdown")
    func failedReplyDoesNotCount() async {
        let manager = await makeTestConversationManager(reply: .failure(TestFailure.unavailable))
        let context = ChatContext(amigo: Amigo.catalogue[0], scenario: nil)
        await #expect(throws: TestFailure.self) { try await manager.send("Hola", in: context) }
        #expect(manager.messagesRemainingForDayStreak == 10)
    }
    @Test("The screen exposes the available friends and current wallet")
    func presentsFriendsAndBalance() async {
        let manager = await makeTestConversationManager()
        let viewModel = ConversationsViewModel(conversations: manager)
        #expect(viewModel.amigos.count == Amigo.catalogue.count)
        #expect(viewModel.doubloons == 10)
        #expect(viewModel.currentStreak == manager.currentStreak)
        #expect(viewModel.currentWeek.map(\.id) == manager.currentWeek.map(\.id))
        #expect(viewModel.preview(for: Amigo.catalogue[0]) == "Start a conversation")
    }

    @Test("A chat row previews its latest saved message")
    func previewsLatestMessage() async {
        let amigo = Amigo.catalogue[0]
        let context = ChatContext(amigo: amigo, scenario: nil)
        var archive = PracticeArchive()
        archive.conversations[context.id] = Conversation(messages: [
            ChatMessage(role: .learner, text: "Hola"),
            ChatMessage(role: .storyteller, text: "¡Qué gusto verte!")
        ])
        let manager = await makeTestConversationManager(archive: archive)
        let viewModel = ConversationsViewModel(conversations: manager)

        #expect(viewModel.preview(for: amigo) == "¡Qué gusto verte!")
    }

    @Test("Search narrows the chat list and clearing it restores every amigo")
    func searchesAmigos() async {
        let manager = await makeTestConversationManager()
        let viewModel = ConversationsViewModel(conversations: manager)

        viewModel.searchText = "inÉS"
        #expect(viewModel.visibleAmigos.map(\.id) == ["ines"])

        viewModel.searchText = ""
        #expect(viewModel.visibleAmigos.count == Amigo.catalogue.count)
    }

    @Test("The streak label uses the singular day when appropriate")
    func streakLabel() async {
        let today = Date(timeIntervalSince1970: 1_780_000_000)
        let calendar = Calendar(identifier: .gregorian)
        let todayKey = String(format: "%04d-%02d-%02d", calendar.component(.year, from: today),
                              calendar.component(.month, from: today), calendar.component(.day, from: today))
        var archive = PracticeArchive()
        archive.practiceDays = [todayKey]
        let manager = await makeTestConversationManager(archive: archive)
        let viewModel = ConversationsViewModel(conversations: manager)
        #expect(viewModel.streakDescription == "1 day")
        #expect(viewModel.hasCompletedDayStreak)
    }
}
