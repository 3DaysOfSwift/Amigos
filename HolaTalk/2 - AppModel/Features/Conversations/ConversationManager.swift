import Foundation
import Observation

@MainActor
@Observable
final class ConversationManager: ConversationFeature {
    private let repository: any ConversationRepository
    private let responder: any SpanishChatResponding
    private let currentDate: @MainActor () -> Date
    private var archive = PracticeArchive()
    private var isMutating = false

    private(set) var isLoaded = false
    private(set) var isResponding = false
    private(set) var loadError: String?

    init(
        repository: any ConversationRepository,
        responder: any SpanishChatResponding,
        currentDate: @escaping @MainActor () -> Date = { .now }
    ) {
        self.repository = repository
        self.responder = responder
        self.currentDate = currentDate
    }

    var doubloons: Int { archive.doubloons }
    var typedWordCount: Int { archive.typedWordCount ?? 0 }
    var uniqueWordCount: Int { archive.typedWords?.count ?? 0 }

    func loadSavedPractice() async {
        guard !isLoaded else { return }
        do {
            var savedPractice = try await repository.load() ?? PracticeArchive()
            if savedPractice.firstOpenedAt == nil {
                let calendar = Calendar(identifier: .gregorian)
                let firstPractice = savedPractice.practiceDays?.compactMap { dayKey -> Date? in
                    let parts = dayKey.split(separator: "-")
                    guard parts.count == 3,
                          let year = Int(parts[0]), let month = Int(parts[1]), let day = Int(parts[2]) else {
                        return nil
                    }
                    return calendar.date(from: DateComponents(year: year, month: month, day: day))
                }.min()
                let firstConversation = savedPractice.conversations.values.compactMap(\.paidAt).min()
                savedPractice.firstOpenedAt = [firstPractice, firstConversation].compactMap { $0 }.min() ?? currentDate()
                try await repository.save(savedPractice)
            }
            archive = savedPractice
            isLoaded = true
            loadError = nil
        } catch {
            loadError = "Your saved practice could not be opened or prepared: \(error.localizedDescription)"
        }
    }

    func conversation(for context: ChatContext) -> Conversation {
        archive.conversations[context.id] ?? Conversation()
    }

    func canStart(_ context: ChatContext) -> Bool {
        let current = conversation(for: context)
        return current.canContinue(until: currentDate()) || doubloons >= context.cost
    }

    func isConversationActive(_ context: ChatContext) -> Bool {
        conversation(for: context).canContinue(until: currentDate())
    }

    func send(_ draft: String, in context: ChatContext) async throws {
        let message = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty else { throw ConversationError.emptyMessage }
        guard message.count <= 500 else { throw ConversationError.messageTooLong }
        guard !isMutating else { throw ConversationError.responseInProgress }
        guard isLoaded else { throw ConversationError.responseInProgress }
        let current = conversation(for: context)
        guard !current.finished else { throw ConversationError.conversationFinished }
        let needsPayment = !current.canContinue(until: currentDate())
        guard !needsPayment || doubloons >= context.cost else { throw ConversationError.insufficientDoubloons }

        isMutating = true
        isResponding = true
        defer { isMutating = false; isResponding = false }

        let learnerMessage = ChatMessage(role: .learner, text: message)
        let reply = try await responder.reply(to: message, context: context, history: current.messages + [learnerMessage])
        try Task.checkCancellation()

        var updated = archive
        var conversation = updated.conversations[context.id] ?? Conversation()
        guard !conversation.finished else { throw ConversationError.conversationFinished }
        if !conversation.canContinue(until: currentDate()) {
            guard updated.doubloons >= context.cost else { throw ConversationError.insufficientDoubloons }
            updated.doubloons -= context.cost
            conversation.paidAt = currentDate()
        }
        conversation.messages.append(learnerMessage)
        conversation.messages.append(ChatMessage(role: .storyteller, text: reply))
        updated.conversations[context.id] = conversation
        let words = message.lowercased().split { !$0.isLetter && !$0.isNumber }.map(String.init)
        updated.typedWordCount = (updated.typedWordCount ?? 0) + words.count
        var uniqueWords = updated.typedWords ?? []
        uniqueWords.formUnion(words.filter { $0.count > 1 })
        updated.typedWords = uniqueWords
        var practiceDays = updated.practiceDays ?? []
        practiceDays.insert(Self.dayKey(currentDate()))
        updated.practiceDays = practiceDays
        try await repository.save(updated)
        archive = updated
    }

    func finishRolePlay(_ context: ChatContext) async throws {
        guard !isMutating else { throw ConversationError.responseInProgress }
        guard let scenario = context.scenario else { return }
        var updated = archive
        var current = conversation(for: context)
        guard !current.finished else { return }
        guard current.messages.filter({ $0.role == .learner }).count >= 3 else {
            throw ConversationError.unfinishedRolePlay
        }
        isMutating = true
        defer { isMutating = false }
        current.finished = true
        updated.conversations[context.id] = current
        updated.completedRolePlays[scenario.id, default: 0] += 1
        try await repository.save(updated)
        archive = updated
    }

    func canFinishRolePlay(_ context: ChatContext) -> Bool {
        context.scenario != nil && !conversation(for: context).finished
            && conversation(for: context).messages.filter({ $0.role == .learner }).count >= 3
    }

    func canClaimDailyChatReward(in context: ChatContext) -> Bool {
        guard archive.lastDailyChatRewardDay != Self.dayKey(currentDate()) else { return false }
        let messages = conversation(for: context).messages
        return messages.filter({ $0.role == .learner }).count >= 3
            && messages.filter({ $0.role == .storyteller }).count >= 3
    }

    func claimDailyChatReward(in context: ChatContext) async throws {
        guard !isMutating else { throw ConversationError.responseInProgress }
        guard canClaimDailyChatReward(in: context) else { return }
        isMutating = true
        defer { isMutating = false }
        var updated = archive
        updated.doubloons += 1
        updated.lastDailyChatRewardDay = Self.dayKey(currentDate())
        try await repository.save(updated)
        archive = updated
    }

    func practiseAgain(_ context: ChatContext) async throws {
        guard !isMutating else { throw ConversationError.responseInProgress }
        isMutating = true
        defer { isMutating = false }
        var updated = archive
        updated.conversations[context.id] = Conversation()
        try await repository.save(updated)
        archive = updated
    }

    func rolePlayCount(_ scenario: RolePlayScenario) -> Int {
        archive.completedRolePlays[scenario.id, default: 0]
    }

    func isRolePlayUnlocked(_ index: Int) -> Bool {
        guard RolePlayScenario.catalogue.indices.contains(index) else { return false }
        return index == 0 || rolePlayCount(RolePlayScenario.catalogue[index - 1]) > 0
    }

    var rolePlayOptions: [RolePlayOption] {
        RolePlayScenario.catalogue.enumerated().map { index, scenario in
            RolePlayOption(
                context: ChatContext(amigo: Amigo.catalogue[index % Amigo.catalogue.count], scenario: scenario),
                isUnlocked: isRolePlayUnlocked(index),
                completionCount: rolePlayCount(scenario)
            )
        }
    }

    var currentStreak: Int {
        let calendar = Calendar(identifier: .gregorian)
        let today = calendar.startOfDay(for: currentDate())
        let practiceDays = archive.practiceDays ?? []
        var day = practiceDays.contains(Self.dayKey(today))
            ? today
            : (calendar.date(byAdding: .day, value: -1, to: today) ?? today)
        var count = 0
        while practiceDays.contains(Self.dayKey(day)) {
            count += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }
        return count
    }

    var daysSinceFirstUse: Int {
        guard let firstOpenedAt = archive.firstOpenedAt else { return 0 }
        let calendar = Calendar(identifier: .gregorian)
        let firstDay = calendar.startOfDay(for: firstOpenedAt)
        let today = calendar.startOfDay(for: currentDate())
        return max(0, calendar.dateComponents([.day], from: firstDay, to: today).day ?? 0)
    }

    var currentWeek: [PracticeDay] {
        let calendar = Calendar(identifier: .gregorian)
        let today = calendar.startOfDay(for: currentDate())
        let daysSinceMonday = (calendar.component(.weekday, from: today) + 5) % 7
        let monday = calendar.date(byAdding: .day, value: -daysSinceMonday, to: today) ?? today
        return (0..<7).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: monday) else { return nil }
            return PracticeDay(date: date, practiced: (archive.practiceDays ?? []).contains(Self.dayKey(date)), today: calendar.isDate(date, inSameDayAs: today))
        }
    }

    nonisolated private static func dayKey(_ date: Date) -> String {
        let calendar = Calendar(identifier: .gregorian)
        return String(format: "%04d-%02d-%02d", calendar.component(.year, from: date),
                      calendar.component(.month, from: date), calendar.component(.day, from: date))
    }
}
