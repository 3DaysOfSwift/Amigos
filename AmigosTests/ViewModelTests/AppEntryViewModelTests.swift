import Testing
@testable import Amigos

@Suite("Application entry screen")
@MainActor
struct AppEntryViewModelTests {
    @Test("Saved practice must load before the streak introduction appears")
    func waitsForSavedPractice() async {
        let manager = ConversationManager(
            repository: MemoryConversationRepository(archive: nil),
            responder: StubSpanishChat(reply: .success("Hola"))
        )
        let viewModel = AppEntryViewModel(conversations: manager, notifications: MessageNotificationsManager())
        #expect(!viewModel.isLoaded)
        await manager.loadSavedPractice()
        #expect(viewModel.isLoaded)
    }

    @Test("A return after five minutes presents the streak moment again")
    func longReturnPresentsStreakMoment() async {
        var date = Date(timeIntervalSince1970: 1_780_000_000)
        let calendar = Calendar(identifier: .gregorian)
        let dayKey = String(format: "%04d-%02d-%02d", calendar.component(.year, from: date),
                            calendar.component(.month, from: date), calendar.component(.day, from: date))
        var archive = PracticeArchive()
        archive.practiceDays = [dayKey]
        let manager = ConversationManager(
            repository: MemoryConversationRepository(archive: archive),
            responder: StubSpanishChat(reply: .success("Hola")),
            currentDate: { date }
        )
        await manager.loadSavedPractice()
        let viewModel = AppEntryViewModel(conversations: manager, currentDate: { date }, notifications: MessageNotificationsManager())

        viewModel.recordAppBecameInactive()
        date = date.addingTimeInterval(5 * 60)
        #expect(viewModel.shouldPresentStreakMomentAfterReturn())
    }

    @Test("A short interruption does not present the streak moment again")
    func shortReturnDoesNotPresentStreakMoment() async {
        var date = Date(timeIntervalSince1970: 1_780_000_000)
        let manager = ConversationManager(
            repository: MemoryConversationRepository(archive: PracticeArchive()),
            responder: StubSpanishChat(reply: .success("Hola")),
            currentDate: { date }
        )
        await manager.loadSavedPractice()
        let viewModel = AppEntryViewModel(conversations: manager, currentDate: { date }, notifications: MessageNotificationsManager())

        viewModel.recordAppBecameInactive()
        date = date.addingTimeInterval(4 * 60 + 59)
        #expect(!viewModel.shouldPresentStreakMomentAfterReturn())
    }
}
