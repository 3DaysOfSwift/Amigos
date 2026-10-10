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
