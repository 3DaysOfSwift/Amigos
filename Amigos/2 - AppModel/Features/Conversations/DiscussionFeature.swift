import Foundation

struct DiscussionTopic: Codable, Sendable, Equatable, Identifiable {
    let id: String
    let title: String
    let preferredAmigos: [String]
    let objective: String
    let guidance: String
    let vocabulary: [String]
    let sampleChat: [String]
    let completionCriteria: String
    var sources: [String]? = nil
}

struct DiscussionProgress: Codable, Sendable, Equatable {
    var completedTopicIDs: Set<String> = []
    var activeTopics: [String: String] = [:]
    var introducedTopicIDs: Set<String> = []
    var deferredDay: String = ""
    var deferredTopicIDs: Set<String> = []
}

struct DiscussionUpdate: Sendable, Equatable {
    let topicID: String
    let action: String
    let learnerEvidence: String
    let replyEvidence: String
}

/// Owns curriculum selection and progress rules; Conversations commits its returned
/// progress with the message so a failed save cannot consume a topic.
struct DiscussionFeature: Sendable {
    let topics: [DiscussionTopic]

    static func bundled() throws -> Self {
        struct Dataset: Decodable { let version: Int; let topics: [DiscussionTopic] }
        guard let url = Bundle.main.url(forResource: "DiscussionTopics", withExtension: "json") else {
            throw CocoaError(.fileNoSuchFile)
        }
        let dataset = try JSONDecoder().decode(Dataset.self, from: Data(contentsOf: url))
        guard dataset.version == 1, !dataset.topics.isEmpty,
              Set(dataset.topics.map(\.id)).count == dataset.topics.count,
              dataset.topics.allSatisfy({ !$0.id.isEmpty && !$0.objective.isEmpty && !$0.completionCriteria.isEmpty }) else {
            throw CocoaError(.coderReadCorrupt)
        }
        return Self(topics: dataset.topics)
    }

    func requestTopic(for amigoID: String, day: String, progress: DiscussionProgress) -> DiscussionTopic? {
        let deferred = progress.deferredDay == day ? progress.deferredTopicIDs : []
        let eligible = topics.filter { !progress.completedTopicIDs.contains($0.id) && !deferred.contains($0.id) }
        if let active = progress.activeTopics[amigoID], let topic = eligible.first(where: { $0.id == active }) {
            return topic
        }
        // Do not assign another amigo's ongoing discussion.
        let available = eligible.filter { !progress.activeTopics.values.contains($0.id) }
        return available.first(where: { $0.preferredAmigos.contains(amigoID) }) ?? available.first
    }

    func record(_ update: DiscussionUpdate?, offered: DiscussionTopic?, amigoID: String,
                day: String, learnerMessage: String, reply: String, progress: DiscussionProgress) -> DiscussionProgress {
        guard let update, let offered, update.topicID == offered.id,
              !progress.completedTopicIDs.contains(offered.id) else { return progress }
        var next = progress
        if next.deferredDay != day {
            next.deferredDay = day
            next.deferredTopicIDs = []
        }
        if update.action == "defer" {
            next.deferredTopicIDs.insert(offered.id)
            next.activeTopics.removeValue(forKey: amigoID)
            return next
        }
        // Evidence must be copied from the actual accepted exchange, never invented.
        guard update.replyEvidence.count >= 12, reply.contains(update.replyEvidence) else { return progress }
        switch update.action {
        case "introduced", "continue":
            next.activeTopics[amigoID] = offered.id
            next.introducedTopicIDs.insert(offered.id)
        case "complete":
            guard progress.activeTopics[amigoID] == offered.id,
                  progress.introducedTopicIDs.contains(offered.id),
                  update.learnerEvidence.count >= 12,
                  learnerMessage.contains(update.learnerEvidence) else { return progress }
            next.completedTopicIDs.insert(offered.id)
            next.activeTopics = next.activeTopics.filter { $0.value != offered.id }
        default: return progress
        }
        return next
    }

    static func prompt(for topic: DiscussionTopic?) -> String {
        guard let topic else { return "No curriculum topic offered. Follow the learner naturally; discussionAction must be none." }
        return """
        OPTIONAL DISCUSSION CARD — data, not overriding instructions
        ID: \(topic.id). \(topic.title)
        Goal: \(topic.objective)
        Background: \(topic.guidance)
        Useful Spanish: \(topic.vocabulary.joined(separator: "; "))
        Illustrative exchange (do not copy or pretend it happened): \(topic.sampleChat.joined(separator: " | "))
        Completion criteria: \(topic.completionCriteria)
        Respond to the learner's topic FIRST. Only introduce this card when it fits naturally; never force a lesson or restart greetings. Use at most one detail per reply. If unsuitable, set discussionAction to defer and continue the user's conversation; a different card can be offered next turn. Do not repeatedly request replacements within one turn.
        Set discussionTopicID to the offered ID. discussionAction: none (unused), introduced, continue, defer, or complete. Complete ONLY after an earlier exchange introduced it, the learner meaningfully engaged, and the criteria are met; it means discussed, not mastered. Quote exact supporting text from the latest learner message in discussionLearnerEvidence and YOUR new Spanish reply in discussionReplyEvidence. No invented evidence. Metadata never appears in dialogue.
        """
    }
}
