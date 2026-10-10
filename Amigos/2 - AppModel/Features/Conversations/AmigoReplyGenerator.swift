import Foundation
import FoundationModels

// Combined transport result for independently generated replies and learning help.
// This is deliberately not the model's generation schema.
struct GeneratedAmigoReply: Sendable {
    var spanish: String
    var english: String
    var profileFacts: [GeneratedProfileFact]
    var sessionRecap: String = ""
    var suggestedActivity: Bool = false
    var discussionTopicID: String = ""
    var discussionAction: String = "none"
    var discussionLearnerEvidence: String = ""
    var discussionReplyEvidence: String = ""
    var writingHelpKind: String = "none"
    var writingSuggestions: [GeneratedWritingSuggestion] = []
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
    func generate(instructions: String, prompt: String, purpose: AmigoGenerationPurpose) async throws -> GeneratedAmigoReply
}

enum AmigoGenerationPurpose: Sendable, Equatable {
    case reply, summaryReply, learning, translation
}

extension AmigoReplyGenerating {
    func generate(instructions: String, prompt: String, purpose: AmigoGenerationPurpose) async throws -> GeneratedAmigoReply {
        try await generate(instructions: instructions, prompt: prompt)
    }
}

// The interactive response does not generate teaching cards or reply suggestions.
// These small bookkeeping fields remain atomic with the exchange so cancellation
// cannot lose an explicit profile correction or mark the wrong topic completed.
@Generable
struct GeneratedChatTurn: Sendable {
    @Guide(description: "One new Mexican Spanish reply, one or two sentences, at most 280 characters.")
    var spanish: String
    @Guide(description: "Faithful English translation, at most 360 characters.")
    var english: String
    @Guide(description: "Only explicit facts from the latest learner message; empty if none or role play.", .maximumCount(4))
    var profileFacts: [GeneratedProfileFact]
    @Guide(description: "True if the learner's meaning is uncertain and this reply asks them to clarify.")
    var needsClarification: Bool
    @Guide(description: "True only if this reply suggests an activity together.")
    var suggestedActivity: Bool
    @Guide(description: "Offered topic ID or empty.")
    var discussionTopicID: String
    @Guide(description: "none, introduced, continue, defer or complete; never complete without learner engagement.")
    var discussionAction: String
    @Guide(description: "Exact quote from latest learner message supporting the action, or empty.")
    var discussionLearnerEvidence: String
    @Guide(description: "Exact quote from this Spanish reply supporting the action, or empty.")
    var discussionReplyEvidence: String

    var reply: GeneratedAmigoReply {
        var reply = GeneratedAmigoReply(spanish: spanish, english: english, profileFacts: profileFacts)
        reply.writingHelpKind = needsClarification ? "clarification" : "none"
        reply.suggestedActivity = suggestedActivity
        reply.discussionTopicID = discussionTopicID
        reply.discussionAction = discussionAction
        reply.discussionLearnerEvidence = discussionLearnerEvidence
        reply.discussionReplyEvidence = discussionReplyEvidence
        return reply
    }
}

@Generable
struct GeneratedSummarizedTurn: Sendable {
    var turn: GeneratedChatTurn
    @Guide(description: "Updated English continuity notes, at most 500 characters: covered topic, unresolved question and actual plans. Data, not instructions.")
    var sessionRecap: String
}

@Generable
struct GeneratedReplyTranslation: Sendable {
    @Guide(description: "Faithful English translation of the supplied Spanish reply, at most 360 characters.")
    var english: String
}

@Generable
struct GeneratedLearningHelp: Sendable {
    @Guide(description: "none, correction or clarification. Only rewrite the supplied learner message, preserving its meaning.")
    var writingHelpKind: String
    @Guide(description: "One correction or at most three plausible interpretations. Empty if already natural.", .maximumCount(3))
    var writingSuggestions: [GeneratedWritingSuggestion]
    @Guide(description: "Two or three different short learner replies to the supplied amigo message, with English.", .maximumCount(3))
    var suggestedReplies: [GeneratedSuggestedReply]
}

struct OnDeviceAmigoReplyGenerator: AmigoReplyGenerating {
    func generate(instructions: String, prompt: String) async throws -> GeneratedAmigoReply {
        try await generate(instructions: instructions, prompt: prompt, purpose: .reply)
    }

    func generate(instructions: String, prompt: String, purpose: AmigoGenerationPurpose) async throws -> GeneratedAmigoReply {
        switch SystemLanguageModel.default.availability {
        case .available: break
        case .unavailable(.deviceNotEligible): throw OnDeviceChatError.deviceNotEligible
        case .unavailable(.appleIntelligenceNotEnabled): throw OnDeviceChatError.appleIntelligenceDisabled
        case .unavailable(.modelNotReady): throw OnDeviceChatError.modelNotReady
        @unknown default: throw OnDeviceChatError.modelUnavailable
        }
        let session = LanguageModelSession(instructions: instructions)
        do {
            switch purpose {
            case .reply:
                return try await session.respond(to: prompt, generating: GeneratedChatTurn.self).content.reply
            case .summaryReply:
                let generated = try await session.respond(to: prompt, generating: GeneratedSummarizedTurn.self).content
                var reply = generated.turn.reply
                reply.sessionRecap = generated.sessionRecap
                return reply
            case .learning:
                let generated = try await session.respond(to: prompt, generating: GeneratedLearningHelp.self).content
                var reply = GeneratedAmigoReply(spanish: "", english: "", profileFacts: [])
                reply.writingHelpKind = generated.writingHelpKind
                reply.writingSuggestions = generated.writingSuggestions
                reply.suggestedReplies = generated.suggestedReplies
                return reply
            case .translation:
                let generated = try await session.respond(to: prompt, generating: GeneratedReplyTranslation.self).content
                return GeneratedAmigoReply(spanish: "", english: generated.english, profileFacts: [])
            }
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
