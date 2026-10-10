import Foundation
import Testing
@testable import Amigos

@Suite("Discussion curriculum")
struct DiscussionFeatureTests {
    private var topic: DiscussionTopic {
        DiscussionTopic(id: "food", title: "Food", preferredAmigos: ["nico"], objective: "Discuss a meal",
            guidance: "Follow their preference", vocabulary: ["casero"], sampleChat: [], completionCriteria: "Share a food preference")
    }

    @Test("Requesting a card never completes it, and preferences guide selection")
    func offer() {
        let feature = DiscussionFeature(topics: [topic])
        let progress = DiscussionProgress()
        #expect(feature.requestTopic(for: "nico", day: "today", progress: progress)?.id == "food")
        #expect(progress.completedTopicIDs.isEmpty)
    }

    @Test("Recovery selects a different library card without completing the rejected topic")
    func recoverySelection() async throws {
        let other = DiscussionTopic(id: "music", title: "Music", preferredAmigos: [], objective: "Discuss music",
            guidance: "Ask about a favourite song", vocabulary: ["canción"], sampleChat: [], completionCriteria: "Share a song")
        let feature = DiscussionFeature(topics: [topic, other])
        let progress = DiscussionProgress(activeTopics: ["nico": "food"])
        let replacement = try #require(feature.requestTopic(for: "nico", day: "today", progress: progress, excluding: "food"))
        #expect(replacement.id == "music")
        #expect(feature.requestTopic(for: "nico", day: "today", progress: DiscussionProgress(completedTopicIDs: ["music"]), excluding: "food") == nil)
        let repeated = "¿Qué comida te gusta preparar con tus amigos?"
        let fresh = "¿Cuál es tu canción favorita para bailar?"
        let generator = ScriptedAmigoGenerator([
            .success(GeneratedAmigoReply(spanish: repeated, english: "What food do you like to prepare with friends?", profileFacts: [])),
            .success(GeneratedAmigoReply(spanish: fresh, english: "What is your favourite song to dance to?", profileFacts: [],
                discussionTopicID: "music", discussionAction: "introduced", discussionReplyEvidence: fresh))
        ])
        let reply = try await OnDeviceSpanishChat(generator: generator).directedReply(to: "Otro tema",
            context: ChatContext(amigo: Amigo.catalogue[1], scenario: nil),
            history: [ChatMessage(role: .storyteller, text: repeated)], profile: nil,
            session: ConversationSessionSummary(day: "today"), topic: topic, recoveryTopic: replacement)
        let prompts = await generator.prompts
        #expect(prompts.count == 2)
        #expect(prompts.first?.contains("ID: food.") == true)
        #expect(prompts.last?.contains("ID: music.") == true)
        #expect(prompts.last?.contains("ID: food.") == false)
        #expect(reply.discussionUpdate?.topicID == "music")
        let saved = feature.record(reply.discussionUpdate, offered: replacement, amigoID: "nico", day: "today",
            learnerMessage: "Bueno, gracias.", reply: reply.spanish, progress: progress)
        #expect(saved.activeTopics["nico"] == "music")
        #expect(saved.completedTopicIDs.isEmpty)
    }

    @Test("Completion needs prior introduction and exact evidence and is shared")
    func completion() {
        let feature = DiscussionFeature(topics: [topic])
        let learner = "Me gusta la sopa de mi padre."
        let reply = "La comida casera trae recuerdos."
        let complete = DiscussionUpdate(topicID: "food", action: "complete", learnerEvidence: learner, replyEvidence: reply)
        let empty = DiscussionProgress()
        #expect(feature.record(complete, offered: topic, amigoID: "nico", day: "today", learnerMessage: learner, reply: reply, progress: empty) == empty)
        let introduced = feature.record(DiscussionUpdate(topicID: "food", action: "introduced", learnerEvidence: "", replyEvidence: reply),
            offered: topic, amigoID: "nico", day: "today", learnerMessage: learner, reply: reply, progress: empty)
        #expect(introduced.completedTopicIDs.isEmpty)
        #expect(feature.record(complete, offered: topic, amigoID: "nico", day: "today", learnerMessage: "Hola", reply: reply, progress: introduced) == introduced)
        let finished = feature.record(complete, offered: topic, amigoID: "nico", day: "today", learnerMessage: learner, reply: reply, progress: introduced)
        #expect(finished.completedTopicIDs == ["food"])
        #expect(feature.requestTopic(for: "alma", day: "tomorrow", progress: finished) == nil)
    }

    @Test("Deferral lasts only for the current day and does not complete the card")
    func deferral() {
        let feature = DiscussionFeature(topics: [topic])
        let next = feature.record(DiscussionUpdate(topicID: "food", action: "defer", learnerEvidence: "", replyEvidence: ""),
            offered: topic, amigoID: "nico", day: "today", learnerMessage: "", reply: "", progress: DiscussionProgress())
        #expect(next.completedTopicIDs.isEmpty)
        #expect(feature.requestTopic(for: "alma", day: "today", progress: next) == nil)
        #expect(feature.requestTopic(for: "alma", day: "tomorrow", progress: next)?.id == "food")
    }

    @Test("Bundled dataset includes the friendship and culture curriculum")
    func dataset() throws {
        let feature = try DiscussionFeature.bundled()
        #expect(feature.topics.count == 100)
        #expect(!feature.topics.contains { $0.id == "library-visit-reflection" })
        #expect(feature.topics.contains { $0.id == "library-visit-choice" })
        #expect(Set(feature.topics.map(\.id)).count == feature.topics.count)
        #expect(Set(feature.topics.map(\.title)).count == feature.topics.count)
        #expect(Set(feature.topics.map(\.id)).isSuperset(of: [
            "ghosts-and-memories", "amigos-and-friendship", "family-remembrance",
            "backpacking-americas", "ai-practice-powerups",
            "restaurant-reservation", "restaurant-order", "restaurant-bill", "supermarket-checkout",
            "buying-car", "clothes-checkout", "online-order-payment", "netflix-monthly-payment",
            "spotify-monthly-payment", "mobile-data-payment", "cinema-online-tickets", "what-are-verbs",
            "conjugating-verbs", "core-spanish-conjugations", "spanish-practice-habit", "tv-at-home",
            "phone-and-friends", "trying-chatgpt", "local-produce-markets", "guatemala-volcano-journey",
            "street-market-prices", "una-cosa", "this-that-those", "my-belongings"
        ]))
        #expect(feature.topics.allSatisfy { $0.vocabulary.count >= 2 && $0.sampleChat.count >= 3 })
    }

    @Test("Failed persistence cannot complete a discussion")
    @MainActor
    func completionRollsBackWithMessage() async throws {
        let firstText = "La comida casera trae recuerdos."
        let nextText = "La sopa de tu padre suena deliciosa."
        let learner = "Me gusta la sopa de mi padre."
        let first = GeneratedAmigoReply(spanish: firstText, english: "Homemade food brings back memories.", profileFacts: [],
            discussionTopicID: "food", discussionAction: "introduced", discussionReplyEvidence: firstText)
        let second = GeneratedAmigoReply(spanish: nextText, english: "Your father's soup sounds delicious.", profileFacts: [],
            discussionTopicID: "food", discussionAction: "complete", discussionLearnerEvidence: learner, discussionReplyEvidence: nextText)
        let repository = MemoryConversationRepository(archive: PracticeArchive())
        let generator = ScriptedAmigoGenerator([.success(first), .success(second), .success(second)])
        let manager = ConversationManager(repository: repository, responder: OnDeviceSpanishChat(generator: generator),
            discussionFeature: DiscussionFeature(topics: [topic]))
        let context = ChatContext(amigo: Amigo.catalogue[1], scenario: nil)
        await manager.loadSavedPractice()
        try await manager.send("Otro tema", in: context)
        await repository.failNextSave()
        await #expect(throws: TestFailure.self) { try await manager.send(learner, in: context) }
        let failedArchive = try #require(await repository.savedArchive())
        #expect(failedArchive.discussionProgress?.completedTopicIDs.isEmpty == true)
        try await manager.send(learner, in: context)
        let savedArchive = try #require(await repository.savedArchive())
        #expect(savedArchive.discussionProgress?.completedTopicIDs == ["food"])
        #expect(savedArchive.conversations[context.id]?.messages.filter { $0.role == .learner }.count == 2)
    }
}
