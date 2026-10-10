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
        #expect(feature.topics.count == 14)
        #expect(Set(feature.topics.map(\.id)).isSuperset(of: [
            "ghosts-and-memories", "amigos-and-friendship", "family-remembrance",
            "backpacking-americas", "ai-practice-powerups"
        ]))
        #expect(feature.topics.allSatisfy { !$0.vocabulary.isEmpty && !$0.sampleChat.isEmpty })
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
        try await manager.send("Hablemos de comida.", in: context)
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
