import Foundation

@MainActor
protocol ConversationFeature: AnyObject {
    var isLoaded: Bool { get }
    var doubloons: Int { get }
    var isResponding: Bool { get }
    var typedWordCount: Int { get }
    var uniqueWordCount: Int { get }
    var currentStreak: Int { get }
    var hasCompletedDayStreak: Bool { get }
    var messagesRemainingForDayStreak: Int { get }
    var daysSinceFirstUse: Int { get }
    var firstJoinedAt: Date? { get }
    var currentWeek: [PracticeDay] { get }
    var launchStreak: Int? { get }
    var dailyAmigoInvitation: DailyAmigoInvitation? { get }
    var rolePlayOptions: [RolePlayOption] { get }
    var amigos: [Amigo] { get }
    var loadError: String? { get }
    var profileNotice: String? { get }
    func introduceFirstAmigo() async throws
    func offersNotificationPermission(in context: ChatContext) -> Bool
    func answerNotificationInvitation(enable: Bool) async throws
    func loadSavedPractice() async
    func prepareStreakLaunch()
    func startSuggestedChat(_ context: ChatContext) async throws
    func conversation(for context: ChatContext) -> Conversation
    func messagesShared(with amigo: Amigo) -> Int
    func amigos(matching query: String) -> [Amigo]
    func canStart(_ context: ChatContext) -> Bool
    func canAuthorizeRolePlay(_ context: ChatContext) -> Bool
    func authorizeRolePlay(_ context: ChatContext) -> Bool
    func isConversationActive(_ context: ChatContext) -> Bool
    func send(_ draft: String, in context: ChatContext) async throws
    func finishRolePlay(_ context: ChatContext) async throws
    func canFinishRolePlay(_ context: ChatContext) -> Bool
    func practiseAgain(_ context: ChatContext) async throws
    func rolePlayCount(_ scenario: RolePlayScenario) -> Int
    func isRolePlayUnlocked(_ index: Int) -> Bool
}

protocol SpanishChatResponding: Sendable {
    func reply(to message: String, context: ChatContext, history: [ChatMessage], profile: LearnerProfile?) async throws -> SpanishChatReply
    func greeting(context: ChatContext, history: [ChatMessage], profile: LearnerProfile?) async throws -> SpanishChatReply
    func greeting(context: ChatContext, history: [ChatMessage]) async throws -> SpanishChatReply
    func reply(to message: String, context: ChatContext, history: [ChatMessage]) async throws -> SpanishChatReply
}

extension SpanishChatResponding {
    func reply(to message: String, context: ChatContext, history: [ChatMessage], profile: LearnerProfile?) async throws -> SpanishChatReply {
        try await reply(to: message, context: context, history: history)
    }

    func greeting(context: ChatContext, history: [ChatMessage], profile: LearnerProfile?) async throws -> SpanishChatReply {
        try await greeting(context: context, history: history)
    }
    func greeting(context: ChatContext, history: [ChatMessage]) async throws -> SpanishChatReply {
        try await reply(to: "Start a friendly conversation with a Spanish hello and one easy question.", context: context, history: history)
    }
}
