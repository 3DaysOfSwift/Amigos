import Foundation
import Testing
@testable import Amigos

@Suite("On-device Amigo response contract")
struct OnDeviceSpanishChatTests {
    private let context = ChatContext(amigo: Amigo.catalogue[3], scenario: nil)
    private var valid: GeneratedAmigoReply {
        GeneratedAmigoReply(spanish: "¡Claro! ¿Qué has aprendido?", english: "Of course! What have you learned?", profileFacts: [])
    }

    @Test("Every chat and greeting request declares English and Spanish", arguments: [false, true])
    func languageContract(rolePlay: Bool) async throws {
        let chat = ChatContext(amigo: context.amigo,
                               scenario: rolePlay ? RolePlayScenario.catalogue[0] : nil)
        let generator = ScriptedAmigoGenerator([
            .failure(.structuredOutput), .success(valid), .success(valid)
        ])
        let responder = OnDeviceSpanishChat(generator: generator)
        _ = try await responder.reply(to: "Escucha bien.", context: chat, history: [])
        _ = try await responder.greeting(context: chat, history: [])
        let prompts = await generator.prompts
        #expect(prompts.count == 3)
        for prompt in prompts {
            #expect(prompt.contains("Expected conversation languages: English (en) and Spanish (es)."))
            #expect(prompt.contains("Spanish (es-MX) in the spanish field"))
            #expect(prompt.contains("English (en) in the english field"))
        }
        #expect(responder.responseInstructions(for: chat).contains(
            "Expected conversation languages: English (en) and Spanish (es)."))
    }

    @Test("Invalid optional facts cannot discard a valid bilingual reply")
    func independentProfileValidation() throws {
        var generated = valid
        generated.profileFacts = [
            GeneratedProfileFact(field: "unknown", value: "Matt", evidence: "Matt"),
            GeneratedProfileFact(field: "homeCountry", value: "Mexico", evidence: "Mexico"),
            GeneratedProfileFact(field: "firstName", value: "Matt", evidence: "Matt")
        ]
        let reply = try OnDeviceSpanishChat().validate(generated, for: context, latestMessage: "I'm Matt")
        #expect(reply.spanish == generated.spanish)
        #expect(reply.profileFacts.map(\.field) == [.firstName])
        #expect(reply.discardedProfileFactCount == 2)
        let rolePlay = ChatContext(amigo: context.amigo, scenario: RolePlayScenario.catalogue[0])
        #expect(try OnDeviceSpanishChat().validate(generated, for: rolePlay, latestMessage: "Matt").profileFacts.isEmpty)
        #expect(try OnDeviceSpanishChat().validate(generated, for: context, latestMessage: nil).profileFacts.isEmpty)
    }

    @Test("Reply failures have distinct categories")
    func distinctValidationFailures() {
        let responder = OnDeviceSpanishChat()
        var generated = valid
        generated.spanish = " "
        #expect(throws: OnDeviceChatError.emptyReply) { try responder.validate(generated, for: context, latestMessage: "Hola") }
        generated = valid
        generated.english = ""
        #expect(throws: OnDeviceChatError.missingTranslation) { try responder.validate(generated, for: context, latestMessage: "Hola") }
        generated = valid
        generated.spanish = String(repeating: "a", count: 281)
        #expect(throws: OnDeviceChatError.replyTooLong) { try responder.validate(generated, for: context, latestMessage: "Hola") }
        generated = valid
        generated.spanish = "Learner: Hola Dani: Hola"
        #expect(throws: OnDeviceChatError.transcriptResponse) { try responder.validate(generated, for: context, latestMessage: "Hola") }
    }

    @Test("English clarification succeeds without extra generation")
    func englishClarification() async throws {
        let generator = ScriptedAmigoGenerator([.success(valid)])
        let responder = OnDeviceSpanishChat(generator: generator)
        let message = "Are you asking me what I have learned so far?"
        let reply = try await responder.reply(to: message, context: context, history: [ChatMessage(role: .learner, text: message)])
        #expect(reply.english == valid.english)
        #expect(await generator.calls == 1)
        let prompt = try #require(await generator.prompts.first)
        #expect(prompt.components(separatedBy: message).count == 2)
    }

    @Test("Recoverable failures get one compact retry", arguments: [OnDeviceChatError.contextLimit, .structuredOutput])
    func boundedRecovery(failure: OnDeviceChatError) async throws {
        let generator = ScriptedAmigoGenerator([.failure(failure), .success(valid)])
        let responder = OnDeviceSpanishChat(generator: generator)
        let history = (0..<8).map { _ in ChatMessage(role: .storyteller, text: String(repeating: "a", count: 250)) }
        let reply = try await responder.reply(to: "Hola", context: context, history: history)
        #expect(reply.spanish == valid.spanish)
        #expect(await generator.calls == 2)
        let prompts = await generator.prompts
        #expect((prompts.last?.count ?? 0) < (prompts.first?.count ?? 0))
    }

    @Test("Invalid bilingual output recovers before being returned")
    func invalidOutputRecovery() async throws {
        var broken = valid
        broken.english = ""
        let generator = ScriptedAmigoGenerator([.success(broken), .success(valid)])
        let reply = try await OnDeviceSpanishChat(generator: generator).reply(to: "Hola", context: context, history: [])
        #expect(reply.english == valid.english)
        #expect(await generator.calls == 2)
    }

    @Test("Persistent failures stop after two attempts")
    func repeatedFailureStops() async {
        let generator = ScriptedAmigoGenerator([.failure(.structuredOutput), .failure(.missingTranslation), .success(valid)])
        await #expect(throws: OnDeviceChatError.missingTranslation) {
            try await OnDeviceSpanishChat(generator: generator).reply(to: "Hola", context: context, history: [])
        }
        #expect(await generator.calls == 2)
    }

    @Test("Safety, availability and busy failures are not retried", arguments: [OnDeviceChatError.safetyRestriction, .refused, .rateLimited, .modelNotReady, .busy, .unsupportedLanguage])
    func nonrecoverableErrors(failure: OnDeviceChatError) async {
        let generator = ScriptedAmigoGenerator([.failure(failure), .success(valid)])
        await #expect(throws: failure) {
            try await OnDeviceSpanishChat(generator: generator).reply(to: "Hola", context: context, history: [])
        }
        #expect(await generator.calls == 1)
    }

    @Test("Cancellation remains cancellation rather than a failed response")
    func cancellation() async {
        await #expect(throws: CancellationError.self) {
            try await OnDeviceSpanishChat(generator: CancelledAmigoGenerator()).reply(to: "Hola", context: context, history: [])
        }
    }
}

private struct CancelledAmigoGenerator: AmigoReplyGenerating {
    func generate(instructions: String, prompt: String) async throws -> GeneratedAmigoReply {
        throw CancellationError()
    }
}
