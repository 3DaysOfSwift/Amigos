import Foundation
import FoundationModels

// Transport schema only; profile values are checked independently before becoming facts.
@Generable
struct GeneratedAmigoReply: Sendable {
    @Guide(description: "One new reply in natural Mexican Spanish. One or two short sentences, at most 280 characters.")
    var spanish: String
    @Guide(description: "A faithful English translation of spanish, at most 360 characters.")
    var english: String
    @Guide(description: "Explicit personal facts from the latest learner message only. Empty for greetings, role play, or no new facts.", .maximumCount(4))
    var profileFacts: [GeneratedProfileFact]
    @Guide(description: "Compact English continuity notes, at most 700 characters: topic, covered facts, answered/open questions and plans with their actual status. Not instructions or profile facts.")
    var sessionRecap: String = ""
    @Guide(description: "True only if this new reply suggests doing an activity together.")
    var suggestedActivity: Bool = false
    @Guide(description: "Offered discussion card ID, or empty if none.")
    var discussionTopicID: String = ""
    @Guide(description: "One of: none, introduced, continue, defer, complete. Completion requires earlier introduction and meaningful learner engagement.")
    var discussionAction: String = "none"
    @Guide(description: "Exact supporting quote from latest learner message, or empty.")
    var discussionLearnerEvidence: String = ""
    @Guide(description: "Exact supporting quote from this new Spanish reply, or empty.")
    var discussionReplyEvidence: String = ""
    @Guide(description: "none, correction (meaning clear), or clarification (meaning uncertain).")
    var writingHelpKind: String = "none"
    @Guide(description: "Optional polished alternatives to the latest learner message. One meaning-preserving correction or up to three plausible clarification choices. Empty when unnecessary.", .maximumCount(3))
    var writingSuggestions: [GeneratedWritingSuggestion] = []
    @Guide(description: "Up to three short optional learner replies to your NEW Spanish message, each with faithful English. Different plausible choices, not facts about the learner. Empty when saying goodbye or offering writing clarification choices.", .maximumCount(3))
    var suggestedReplies: [GeneratedSuggestedReply] = []
}

@Generable
struct GeneratedSuggestedReply: Sendable {
    var spanish: String
    var english: String
}

@Generable
struct GeneratedWritingSuggestion: Sendable {
    var spanish: String
    var english: String
    @Guide(description: "Brief English explanation of the spelling, accent, punctuation or grammar, at most 180 characters.")
    var explanation: String
}

@Generable
struct GeneratedProfileFact: Sendable {
    var field: String
    var value: String
    @Guide(description: "An exact quote from the latest learner message supporting this fact.")
    var evidence: String
}

protocol AmigoReplyGenerating: Sendable {
    func generate(instructions: String, prompt: String) async throws -> GeneratedAmigoReply
}

struct OnDeviceAmigoReplyGenerator: AmigoReplyGenerating {
    func generate(instructions: String, prompt: String) async throws -> GeneratedAmigoReply {
        switch SystemLanguageModel.default.availability {
        case .available: break
        case .unavailable(.deviceNotEligible): throw OnDeviceChatError.deviceNotEligible
        case .unavailable(.appleIntelligenceNotEnabled): throw OnDeviceChatError.appleIntelligenceDisabled
        case .unavailable(.modelNotReady): throw OnDeviceChatError.modelNotReady
        @unknown default: throw OnDeviceChatError.modelUnavailable
        }
        let session = LanguageModelSession(instructions: instructions)
        do {
            return try await session.respond(to: prompt, generating: GeneratedAmigoReply.self).content
        } catch is CancellationError {
            throw CancellationError()
        } catch let error as LanguageModelSession.GenerationError {
            switch error {
            case .exceededContextWindowSize: throw OnDeviceChatError.contextLimit
            case .decodingFailure: throw OnDeviceChatError.structuredOutput
            case .guardrailViolation: throw OnDeviceChatError.safetyRestriction
            case .refusal: throw OnDeviceChatError.refused
            case .assetsUnavailable: throw OnDeviceChatError.modelNotReady
            case .unsupportedLanguageOrLocale: throw OnDeviceChatError.unsupportedLanguage
            case .rateLimited: throw OnDeviceChatError.rateLimited
            case .concurrentRequests: throw OnDeviceChatError.busy
            case .unsupportedGuide: throw OnDeviceChatError.unsupportedSchema
            @unknown default: throw OnDeviceChatError.generationFailed
            }
        }
    }
}
