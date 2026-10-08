import Foundation

@MainActor
protocol ConversationFeature: AnyObject {
    var isLoaded: Bool { get }
    var doubloons: Int { get }
    var isResponding: Bool { get }
    var typedWordCount: Int { get }
    var uniqueWordCount: Int { get }
    var currentStreak: Int { get }
    var daysSinceFirstUse: Int { get }
    var currentWeek: [PracticeDay] { get }
    var rolePlayOptions: [RolePlayOption] { get }
    var amigos: [Amigo] { get }
    var loadError: String? { get }
    func loadSavedPractice() async
    func conversation(for context: ChatContext) -> Conversation
    func messagesShared(with amigo: Amigo) -> Int
    func amigos(matching query: String) -> [Amigo]
    func canStart(_ context: ChatContext) -> Bool
    func isConversationActive(_ context: ChatContext) -> Bool
    func send(_ draft: String, in context: ChatContext) async throws
    func finishRolePlay(_ context: ChatContext) async throws
    func canFinishRolePlay(_ context: ChatContext) -> Bool
    func canClaimDailyChatReward(in context: ChatContext) -> Bool
    func claimDailyChatReward(in context: ChatContext) async throws
    func practiseAgain(_ context: ChatContext) async throws
    func rolePlayCount(_ scenario: RolePlayScenario) -> Int
    func isRolePlayUnlocked(_ index: Int) -> Bool
}

protocol SpanishChatResponding: Sendable {
    func reply(to message: String, context: ChatContext, history: [ChatMessage]) async throws -> String
}
