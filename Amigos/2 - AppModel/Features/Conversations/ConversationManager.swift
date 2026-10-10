import Foundation
import Observation
import OSLog

@MainActor
@Observable
final class ConversationManager: ConversationFeature {
    private static let logger = Logger(subsystem: "com.3DaysOfSwiftConcurrency.Amigos", category: "ChatProfile")
    private let repository: any ConversationRepository
    private let responder: any SpanishChatResponding
    private let currentDate: @MainActor () -> Date
    private let profileFeature: (any ProfileFeature)?
    private let notifications: (any AmigoMessageNotifying)?
    private(set) var profileNotice: String?
    private var archive = PracticeArchive()
    private var isMutating = false
    private var authorizedRolePlayID: String?
    private var discussionFeature: DiscussionFeature?

    private(set) var isLoaded = false
    private(set) var isResponding = false
    private(set) var loadError: String?
    private(set) var launchStreak: Int?
    private(set) var dailyAmigoInvitation: DailyAmigoInvitation?

    init(
        repository: any ConversationRepository,
        responder: any SpanishChatResponding,
        currentDate: @escaping @MainActor () -> Date = { .now },
        profileFeature: (any ProfileFeature)? = nil,
        notifications: (any AmigoMessageNotifying)? = nil,
        discussionFeature: DiscussionFeature? = nil
    ) {
        self.repository = repository
        self.responder = responder
        self.currentDate = currentDate
        self.profileFeature = profileFeature
        self.notifications = notifications
        self.discussionFeature = discussionFeature
    }

    var doubloons: Int { archive.doubloons }
    var typedWordCount: Int { archive.typedWordCount ?? 0 }
    var uniqueWordCount: Int { archive.typedWords?.count ?? 0 }
    var amigos: [Amigo] { Amigo.catalogue }

    func amigos(matching query: String) -> [Amigo] {
        let search = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !search.isEmpty else { return amigos }
        return amigos.filter { $0.name.localizedCaseInsensitiveContains(search) }
    }

    func loadSavedPractice() async {
        guard !isLoaded else { return }
        do {
            if discussionFeature == nil { discussionFeature = try DiscussionFeature.bundled() }
            var savedPractice = try await repository.load() ?? PracticeArchive()
            if savedPractice.firstOpenedAt == nil {
                savedPractice.firstOpenedAt = currentDate()
                try await repository.save(savedPractice)
            }
            archive = savedPractice
            isLoaded = true
            prepareStreakLaunch()
            loadError = nil
        } catch {
            loadError = "Your saved practice could not be opened or prepared: \(error.localizedDescription)"
        }
    }

    func conversation(for context: ChatContext) -> Conversation {
        archive.conversations[context.id] ?? Conversation()
    }

    func startNewConversation(_ context: ChatContext) async throws {
        guard isLoaded, !isMutating else { throw ConversationError.responseInProgress }
        guard context.scenario == nil else { return }
        isMutating = true
        defer { isMutating = false }
        var updated = archive
        var conversation = conversation(for: context)
        // Recovery does not depend on another successful model generation.
        var greeting = ChatMessage(role: .storyteller, text: "¡Hola! ¿Cómo te va hoy?",
                                   englishText: "Hi! How are things going today?")
        greeting.startsNewConversation = !conversation.messages.isEmpty
        conversation.messages.append(greeting)
        conversation.contextStartMessageID = greeting.id
        conversation.sessionSummary = nil
        updated.conversations[context.id] = conversation
        updated.discussionProgress?.activeTopics.removeValue(forKey: context.amigo.id)
        try await repository.save(updated)
        archive = updated
    }

    func clearConversation(_ context: ChatContext) async throws {
        guard isLoaded, !isMutating else { throw ConversationError.responseInProgress }
        guard context.scenario == nil else { return }
        isMutating = true
        defer { isMutating = false }
        var updated = archive
        updated.conversations.removeValue(forKey: context.id)
        updated.discussionProgress?.activeTopics.removeValue(forKey: context.amigo.id)
        try await repository.save(updated)
        archive = updated
    }

    func startSuggestedChat(_ context: ChatContext) async throws {
        guard context.startsWithGreeting, context.scenario == nil, isLoaded else { return }
        let today = streakDayKey(for: currentDate(), archive: archive)
        let existing = conversation(for: context)
        guard existing.lastGreetingDay != today else { return }
        guard !isMutating else { throw ConversationError.responseInProgress }
        isMutating = true
        isResponding = true
        defer { isMutating = false; isResponding = false }
        var session = existing.sessionSummary?.forDay(today) ?? ConversationSessionSummary(day: today)
        let reply = try await responder.greeting(context: context, history: existing.activeMessages, profile: profileFeature?.profile, session: session)
        try Task.checkCancellation()
        var updated = archive
        var conversation = existing
        var greeting = ChatMessage(role: .storyteller, text: reply.spanish, englishText: reply.english)
        greeting.suggestedReplies = reply.suggestedReplies
        greeting.startsNewConversation = !existing.messages.isEmpty
        conversation.messages.append(greeting)
        conversation.lastGreetingDay = today
        session.record(reply)
        conversation.sessionSummary = session
        updated.conversations[context.id] = conversation
        try await repository.save(updated)
        archive = updated
    }

    func messagesShared(with amigo: Amigo) -> Int {
        let context = ChatContext(amigo: amigo, scenario: nil)
        return conversation(for: context).messages.filter { $0.role == .learner }.count
    }

    func canStart(_ context: ChatContext) -> Bool {
        guard isLoaded, !conversation(for: context).finished else { return false }
        guard context.scenario != nil else { return true }
        let current = conversation(for: context)
        return current.canContinue(until: currentDate())
            || (authorizedRolePlayID == context.id && doubloons >= context.cost)
    }

    func canAuthorizeRolePlay(_ context: ChatContext) -> Bool {
        context.scenario != nil && isLoaded && !isMutating
            && !conversation(for: context).finished && doubloons >= context.cost
    }

    func authorizeRolePlay(_ context: ChatContext) -> Bool {
        guard canAuthorizeRolePlay(context) else { return false }
        authorizedRolePlayID = context.id
        return true
    }

    func isConversationActive(_ context: ChatContext) -> Bool {
        conversation(for: context).canContinue(until: currentDate())
    }

    /// Revises one accepted exchange, never a second reward or admission purchase.
    func acceptWritingSuggestion(_ suggestion: WritingSuggestion, messageID: UUID, in context: ChatContext) async throws {
        guard !isMutating, isLoaded else { throw ConversationError.responseInProgress }
        let current = conversation(for: context)
        guard !current.finished,
              let index = current.messages.lastIndex(where: { $0.role == .learner }),
              current.messages[index].id == messageID,
              let help = current.messages[index].writingHelp,
              help.suggestions.contains(suggestion),
              current.messages.count > index + 1 else { throw ConversationError.correctionUnavailable }
        isMutating = true
        isResponding = help.kind == .clarification
        defer { isMutating = false; isResponding = false }
        let original = current.messages[index]
        var replacement = ChatMessage(id: original.id, role: .learner, text: suggestion.spanish, englishText: suggestion.english)
        replacement.originalText = original.originalText ?? original.text
        replacement.learningHelpPrepared = true
        var revised = current
        revised.messages[index] = replacement
        if help.kind == .clarification {
            // Only replace the immediate clarification, leaving app notices untouched.
            guard current.messages[index + 1].role == .storyteller else { throw ConversationError.correctionUnavailable }
            let reply = try await responder.reply(to: suggestion.spanish, context: context,
                history: Array(revised.activeMessages.dropLast(revised.messages.count - index - 1)), profile: profileFeature?.profile)
            try Task.checkCancellation()
            revised.messages[index + 1] = ChatMessage(id: current.messages[index + 1].id,
                role: .storyteller, text: reply.spanish, englishText: reply.english)
            revised.messages[index + 1].suggestedReplies = reply.suggestedReplies
            // Unconfirmed interpretations must not become durable continuity facts.
            revised.sessionSummary?.recap = reply.sessionRecap ?? ""
        }
        try Task.checkCancellation()
        var updated = archive
        updated.conversations[context.id] = revised
        try await repository.save(updated)
        archive = updated
    }

    func send(_ draft: String, in context: ChatContext) async throws {
        let sendStart = ContinuousClock.now
        let message = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty else { throw ConversationError.emptyMessage }
        guard message.count <= 500 else { throw ConversationError.messageTooLong }
        guard !isMutating else { throw ConversationError.responseInProgress }
        guard isLoaded else { throw ConversationError.responseInProgress }
        let current = conversation(for: context)
        guard !current.finished else { throw ConversationError.conversationFinished }
        let needsPayment = context.scenario != nil && !current.canContinue(until: currentDate())
        guard !needsPayment || doubloons >= context.cost else { throw ConversationError.insufficientDoubloons }
        guard !needsPayment || authorizedRolePlayID == context.id else { throw ConversationError.rolePlayNotAuthorized }

        isMutating = true
        isResponding = true
        defer { isMutating = false; isResponding = false }

        var learnerMessage = ChatMessage(role: .learner, text: message)
        let sessionDay = streakDayKey(for: currentDate(), archive: archive)
        var session = current.sessionSummary?.forDay(sessionDay) ?? ConversationSessionSummary(day: sessionDay)
        let discussionProgress = archive.discussionProgress ?? DiscussionProgress()
        let topic = context.scenario == nil ? discussionFeature?.requestTopic(
            for: context.amigo.id, day: sessionDay, progress: discussionProgress) : nil
        let recoveryTopic = context.scenario == nil ? discussionFeature?.requestTopic(
            for: context.amigo.id, day: sessionDay, progress: discussionProgress, excluding: topic?.id) : nil
        let reply = try await responder.directedReply(to: message, context: context,
            history: current.activeMessages + [learnerMessage], profile: profileFeature?.profile,
            session: session, topic: topic, recoveryTopic: recoveryTopic)
        try Task.checkCancellation()

        var updated = archive
        var conversation = updated.conversations[context.id] ?? Conversation()
        if context.scenario == nil, let discussionFeature {
            updated.discussionProgress = discussionFeature.record(reply.discussionUpdate,
                offered: [topic, recoveryTopic].compactMap { $0 }.first { $0.id == reply.discussionUpdate?.topicID }, amigoID: context.amigo.id, day: sessionDay,
                learnerMessage: message, reply: reply.spanish, progress: discussionProgress)
        }
        guard !conversation.finished else { throw ConversationError.conversationFinished }
        if context.scenario != nil && !conversation.canContinue(until: currentDate()) {
            guard updated.doubloons >= context.cost else { throw ConversationError.insufficientDoubloons }
            guard authorizedRolePlayID == context.id else { throw ConversationError.rolePlayNotAuthorized }
            updated.doubloons -= context.cost
            conversation.paidAt = currentDate()
        }
        learnerMessage.writingHelp = reply.writingHelp
        conversation.messages.append(learnerMessage)
        var amigoMessage = ChatMessage(role: .storyteller, text: reply.spanish, englishText: reply.english)
        amigoMessage.suggestedReplies = reply.suggestedReplies
        conversation.messages.append(amigoMessage)
        session.record(reply)
        conversation.sessionSummary = session
        updated.conversations[context.id] = conversation
        let words = message.lowercased().split { !$0.isLetter && !$0.isNumber }.map(String.init)
        updated.typedWordCount = (updated.typedWordCount ?? 0) + words.count
        var uniqueWords = updated.typedWords ?? []
        uniqueWords.formUnion(words.filter { $0.count > 1 })
        updated.typedWords = uniqueWords
        if context.scenario == nil {
            let today = streakDayKey(for: currentDate(), archive: updated)
            var progress = updated.dailyAmigoChatProgress?[context.amigo.id]
            if progress?.day != today {
                progress = DailyAmigoChatProgress(day: today,
                                                  successfulExchanges: 0,
                                                  awardedDoubloons: 0)
            }
            if var progress {
                progress.successfulExchanges += 1
                let earned = progress.successfulExchanges < 10
                    ? 0 : 1 + (progress.successfulExchanges - 10) / 40
                if earned > progress.awardedDoubloons {
                    updated.doubloons += earned - progress.awardedDoubloons
                    if updated.hasExplainedDoubloons != true {
                        let explanation = AmigoWelcome.doubloonExplanation
                        conversation.messages.append(ChatMessage(role: .storyteller, text: explanation.spanish, englishText: explanation.english))
                        updated.conversations[context.id] = conversation
                        updated.hasExplainedDoubloons = true
                    }
                    progress.awardedDoubloons = earned
                    updated.streakTimeZoneIdentifier = TimeZone.current.identifier
                    var streakDays = updated.practiceDays ?? []
                    streakDays.insert(streakDayKey(for: currentDate(), archive: updated))
                    updated.practiceDays = streakDays
                }
                var dailyProgress = updated.dailyAmigoChatProgress ?? [:]
                dailyProgress[context.amigo.id] = progress
                updated.dailyAmigoChatProgress = dailyProgress
            }
        }
        let saveStart = ContinuousClock.now
        try await repository.save(updated)
        archive = updated
        isResponding = false
        Self.logger.info("stage=reply_commit saveDuration=\(String(describing: saveStart.duration(to: .now)), privacy: .public) totalDuration=\(String(describing: sendStart.duration(to: .now)), privacy: .public)")
        if needsPayment { authorizedRolePlayID = nil }
        profileNotice = reply.discardedProfileFactCount > 0
            ? "Some profile details couldn't be remembered. You can add them in Settings → Your profile."
            : nil
        if context.scenario == nil, !reply.profileFacts.isEmpty, let profileFeature {
            do {
                let fields = try await profileFeature.remember(reply.profileFacts, from: message)
                if !fields.isEmpty {
                    let savedNotice = "Profile updated: \(fields.map(\.title).joined(separator: ", ")). You can edit or remove these details in Settings → Your profile."
                    profileNotice = [profileNotice, savedNotice].compactMap { $0 }.joined(separator: " ")
                }
            } catch {
                let failureType = String(reflecting: type(of: error))
                Self.logger.error("stage=profile_update failureType=\(failureType, privacy: .public)")
                profileNotice = "Your message was saved, but your profile could not be updated. You can edit it in Settings."
            }
        }
        // The reply is committed before introducing another friend. A welcome never counts as an exchange.
        if context.scenario == nil, archive.introducedAmigoIDs?.last == context.amigo.id,
           context.amigo.id != "nico",
           (context.amigo.id != "alma" || archive.hasExplainedDoubloons == true) {
            do { try await introduceNextAmigo() }
            catch { profileNotice = "Your reply was saved. The next amigo's introduction could not be saved; try again later." }
        }
    }

    /// Optional teaching is cached on the accepted exchange; it cannot award coins
    /// or replace chat text. The caller owns cancellation and must await it before sending.
    func prepareLearningHelp(in context: ChatContext) async throws {
        try Task.checkCancellation()
        guard isLoaded, !isMutating else { throw ConversationError.responseInProgress }
        let current = conversation(for: context)
        guard !current.finished, let last = current.messages.last, last.role == .storyteller else { return }
        guard last.learningHelpPrepared != true else { return }
        isMutating = true
        defer { isMutating = false }
        let learner = current.activeMessages.last { $0.role == .learner }
        let help = try await responder.learningHelp(context: context, learner: learner, reply: last)
        try Task.checkCancellation()
        guard conversation(for: context).messages.last?.id == last.id else { return }
        var updated = archive
        var revised = current
        if let index = revised.messages.firstIndex(where: { $0.id == learner?.id }) {
            revised.messages[index].writingHelp = help.writingHelp
            revised.messages[index].learningHelpPrepared = true
        }
        if let index = revised.messages.firstIndex(where: { $0.id == last.id }) {
            revised.messages[index].suggestedReplies = help.suggestedReplies
            revised.messages[index].learningHelpPrepared = true
        }
        updated.conversations[context.id] = revised
        try await repository.save(updated)
        archive = updated
    }

    func introduceFirstAmigo() async throws {
        guard isLoaded, archive.introducedAmigoIDs?.isEmpty != false,
              archive.conversations.isEmpty else { return }
        guard !isMutating else { throw ConversationError.responseInProgress }
        isMutating = true
        defer { isMutating = false }
        try await introduceNextAmigo()
    }

    func offersNotificationPermission(in context: ChatContext) -> Bool {
        context.scenario == nil && context.amigo.id == "nico"
            && archive.introducedAmigoIDs?.contains("nico") == true
            && archive.hasAnsweredNotificationInvitation != true
    }

    func answerNotificationInvitation(enable: Bool) async throws {
        guard isLoaded, !isMutating else { throw ConversationError.responseInProgress }
        guard archive.introducedAmigoIDs?.last == "nico",
              archive.hasAnsweredNotificationInvitation != true else { return }
        isMutating = true
        defer { isMutating = false }
        let allowed: Bool
        if enable {
            guard let notifications else { throw ConversationError.responseInProgress }
            allowed = try await notifications.requestPermission()
        } else {
            allowed = false
        }
        try await introduceNextAmigo(notificationAllowed: allowed)
    }

    private func introduceNextAmigo(notificationAllowed: Bool? = nil) async throws {
        let introduced = archive.introducedAmigoIDs ?? []
        guard let amigo = amigos.first(where: { $0.id != "tavo" && !introduced.contains($0.id) }) else { return }
        let welcome = AmigoWelcome.message(for: amigo)
        var message = ChatMessage(role: .storyteller, text: welcome.spanish, englishText: welcome.english)
        var updated = archive
        if let notificationAllowed {
            updated.hasAnsweredNotificationInvitation = true
            var nicoChat = updated.conversations["chat:nico"] ?? Conversation()
            nicoChat.messages.append(ChatMessage(role: .storyteller,
                text: notificationAllowed ? "¡Listo! Podemos avisarte cuando llegue un mensaje. ¡Inés quiere saludarte!" : "¡Sin problema! Puedes seguir hablando con todos aquí. Si cambias de idea, activa las notificaciones en Ajustes de iOS. ¡Inés quiere saludarte!",
                englishText: notificationAllowed ? "All set! We can notify you when a message arrives. Inés wants to say hello!" : "No problem! You can still chat with everyone here. If you change your mind, enable notifications in iOS Settings. Inés wants to say hello!"))
            updated.conversations["chat:nico"] = nicoChat
        }
        let context = ChatContext(amigo: amigo, scenario: nil)
        var chat = conversation(for: context)
        message.startsNewConversation = !chat.messages.isEmpty
        chat.messages.append(message)
        updated.conversations[context.id] = chat
        updated.introducedAmigoIDs = introduced + [amigo.id]
        try await repository.save(updated)
        archive = updated
        await notifications?.notify(amigo: amigo, message: message)
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
        let calendar = streakCalendar
        let today = calendar.startOfDay(for: currentDate())
        let practiceDays = archive.practiceDays ?? []
        var day = practiceDays.contains(Self.dayKey(today, calendar: calendar))
            ? today
            : (calendar.date(byAdding: .day, value: -1, to: today) ?? today)
        var count = 0
        while practiceDays.contains(Self.dayKey(day, calendar: calendar)) {
            count += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }
        return count
    }

    var hasCompletedDayStreak: Bool {
        let calendar = streakCalendar
        let today = calendar.startOfDay(for: currentDate())
        return (archive.practiceDays ?? []).contains(Self.dayKey(today, calendar: calendar))
    }

    var messagesRemainingForDayStreak: Int {
        guard !hasCompletedDayStreak else { return 0 }
        let today = streakDayKey(for: currentDate(), archive: archive)
        let mostExchanges = (archive.dailyAmigoChatProgress ?? [:]).values
            .filter { $0.day == today }
            .map(\.successfulExchanges)
            .max() ?? 0
        return max(0, 10 - mostExchanges)
    }

    func hasEarnedDoubloonToday(with amigo: Amigo) -> Bool {
        guard let progress = archive.dailyAmigoChatProgress?[amigo.id] else { return false }
        let today = streakDayKey(for: currentDate(), archive: archive)
        return progress.day == today && progress.awardedDoubloons > 0
    }

    var daysSinceFirstUse: Int {
        guard let firstOpenedAt = archive.firstOpenedAt else { return 0 }
        let calendar = Calendar(identifier: .gregorian)
        let firstDay = calendar.startOfDay(for: firstOpenedAt)
        let today = calendar.startOfDay(for: currentDate())
        return max(0, calendar.dateComponents([.day], from: firstDay, to: today).day ?? 0)
    }

    var firstJoinedAt: Date? { archive.firstOpenedAt }

    var currentWeek: [PracticeDay] {
        let calendar = streakCalendar
        let today = calendar.startOfDay(for: currentDate())
        let daysSinceMonday = (calendar.component(.weekday, from: today) + 5) % 7
        let monday = calendar.date(byAdding: .day, value: -daysSinceMonday, to: today) ?? today
        return (0..<7).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: monday) else { return nil }
            return PracticeDay(date: date, practiced: (archive.practiceDays ?? []).contains(Self.dayKey(date, calendar: calendar)), today: calendar.isDate(date, inSameDayAs: today))
        }
    }

    private var streakCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: archive.streakTimeZoneIdentifier ?? TimeZone.current.identifier) ?? .current
        return calendar
    }

    func prepareStreakLaunch() {
        launchStreak = nil
        dailyAmigoInvitation = nil
        guard isLoaded, currentStreak > 0 else { return }

        launchStreak = currentStreak
        guard !amigos.isEmpty,
              let day = streakCalendar.ordinality(of: .day, in: .era, for: currentDate()) else { return }
        let amigo = amigos[day % amigos.count]
        dailyAmigoInvitation = DailyAmigoInvitation(amigo: amigo, streak: currentStreak)
    }

    private func streakDayKey(for date: Date, archive: PracticeArchive) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: archive.streakTimeZoneIdentifier ?? TimeZone.current.identifier) ?? .current
        return Self.dayKey(date, calendar: calendar)
    }

    nonisolated private static func dayKey(_ date: Date, calendar: Calendar) -> String {
        return String(format: "%04d-%02d-%02d", calendar.component(.year, from: date),
                      calendar.component(.month, from: date), calendar.component(.day, from: date))
    }
}
