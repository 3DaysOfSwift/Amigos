import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

struct OnDeviceSpanishChat: SpanishChatResponding {
    func reply(to message: String, context: ChatContext, history: [ChatMessage]) async throws -> String {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            switch SystemLanguageModel.default.availability {
            case .available:
                break
            case .unavailable(.deviceNotEligible):
                throw OnDeviceChatError.deviceNotEligible
            case .unavailable(.appleIntelligenceNotEnabled):
                throw OnDeviceChatError.appleIntelligenceDisabled
            case .unavailable(.modelNotReady):
                throw OnDeviceChatError.modelNotReady
            @unknown default:
                throw OnDeviceChatError.modelUnavailable
            }
            let situation: String
            if let scenario = context.scenario {
                situation = "You are \(context.amigo.name), a friendly fictional skeleton playing a \(scenario.aiRole) in \(scenario.context). The learner is a \(scenario.learnerRole). Their objective is: \(scenario.objective) Ask one practical thing at a time. Do not speak for the learner. Adapt to imperfect Spanish when the meaning is clear."
            } else {
                situation = "You are \(context.amigo.name), \(context.amigo.identity). Your voice is \(context.amigo.voice). You are a fictional Spanish-speaking skeleton friend texting the learner. You know you are a skeleton and may joke gently about it, but keep the chat warm rather than morbid. Ask about their life, respond naturally, and never claim to be a real person."
            }
            let recent = history.suffix(8).map { "\($0.role == .learner ? "Learner" : context.title): \($0.text)" }.joined(separator: "\n")
            let session = LanguageModelSession(instructions: """
            \(situation)
            Use Mexican Spanish. Reply as a chat message in one or two short sentences. Do not produce a lesson, headings, markdown, translations, or a list. You may kindly correct an important mistake inside the natural reply.
            """)
            let response = try await session.respond(to: "Conversation so far:\n\(recent)\n\nReply to the learner’s newest message naturally.")
            let reply = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !reply.isEmpty else { throw OnDeviceChatError.emptyResponse }
            return reply
        }
        #endif
        throw OnDeviceChatError.modelUnavailable
    }
}

enum OnDeviceChatError: LocalizedError {
    case modelUnavailable, deviceNotEligible, appleIntelligenceDisabled, modelNotReady, emptyResponse

    var errorDescription: String? {
        switch self {
        case .modelUnavailable:
            "On-device chat needs iOS 26 and Apple Intelligence enabled on a supported device. No doubloons were spent."
        case .deviceNotEligible:
            "This device does not support Apple Intelligence. No doubloons were spent."
        case .appleIntelligenceDisabled:
            "Turn on Apple Intelligence in Settings to chat. No doubloons were spent."
        case .modelNotReady:
            "The on-device language model is still getting ready. Try again later; no doubloons were spent."
        case .emptyResponse:
            "Your chat partner did not reply. Please try again. No doubloons were spent."
        }
    }
}
