import Observation

@MainActor
@Observable
final class PracticeProgressViewModel {
    private let conversations: any ConversationFeature

    init(conversations: any ConversationFeature = AppModel.shared.conversationsManager) {
        self.conversations = conversations
    }

    var doubloons: Int { conversations.doubloons }
    var currentStreak: Int { conversations.currentStreak }
    var streakDescription: String { "\(currentStreak) \(currentStreak == 1 ? "day" : "days")" }
    var daysSinceFirstUse: Int { conversations.daysSinceFirstUse }
    var currentWeek: [PracticeDay] { conversations.currentWeek }
    var uniqueWordCount: Int { conversations.uniqueWordCount }
    var typedWordCount: Int { conversations.typedWordCount }
    var practicedToday: Bool { currentWeek.contains { $0.today && $0.practiced } }

}
