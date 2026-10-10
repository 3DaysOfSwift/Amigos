import Foundation
import Testing
@testable import Amigos

@Suite("Conversation direction and continuity")
struct ConversationDirectionTests {
    @Test("Daily state resets without losing continuity notes")
    func newDay() throws {
        let summary = ConversationSessionSummary(day: "2026-10-10", recap: "Coffee proposed, not completed.",
                                                 exchangedReplies: 4, activitySuggested: true)
        #expect(summary.forDay(summary.day) == summary)
        let tomorrow = summary.forDay("2026-10-11")
        #expect(tomorrow.recap == summary.recap)
        #expect(tomorrow.exchangedReplies == 0)
        #expect(!tomorrow.activitySuggested)
        let conversation = Conversation(sessionSummary: summary)
        let decoded = try JSONDecoder().decode(Conversation.self, from: JSONEncoder().encode(conversation))
        #expect(decoded.sessionSummary == summary)
    }

    @Test("Invalid notes preserve prior notes and invitation flags are monotonic")
    func boundedNotes() {
        var summary = ConversationSessionSummary(day: "2026-10-10", recap: "Music discussed.", activitySuggested: true)
        summary.record(SpanishChatReply(spanish: "Claro", english: "Of course", sessionRecap: String(repeating: "x", count: 701)))
        #expect(summary.recap == "Music discussed.")
        #expect(summary.activitySuggested)
        #expect(summary.exchangedReplies == 1)
    }

    @Test("A repeated coffee invitation is corrected once before delivery")
    func repeatedCoffeeReply() async throws {
        let coffee = "¿Qué tal si nos tomamos un café y me cuentas un poco de tu día?"
        let repeated = GeneratedAmigoReply(spanish: coffee, english: "Shall we have coffee and talk about your day?", profileFacts: [])
        let corrected = GeneratedAmigoReply(spanish: "¡Vamos! Yo prefiero el café de olla, con canela.",
            english: "Let's go! I prefer café de olla, with cinnamon.", profileFacts: [],
            sessionRecap: "Coffee accepted; café de olla introduced. Do not invite again.")
        let generator = ScriptedAmigoGenerator([.success(repeated), .success(corrected)])
        let responder = OnDeviceSpanishChat(generator: generator)
        let context = ChatContext(amigo: Amigo.catalogue[0], scenario: nil)
        let session = ConversationSessionSummary(day: "2026-10-10", recap: "Coffee was suggested.", activitySuggested: true)
        let result = try await responder.reply(to: "Perfecto, vamos.", context: context,
            history: [ChatMessage(role: .storyteller, text: coffee)], profile: nil, session: session)
        #expect(result.spanish == corrected.spanish)
        #expect(result.sessionRecap == corrected.sessionRecap)
        #expect(await generator.calls == 2)
        for prompt in await generator.prompts {
            #expect(prompt.contains("Coffee was suggested."))
            #expect(prompt.contains("yes; do not suggest another"))
        }
    }

    @Test("Persistent repetition remains a specific bounded failure")
    func persistentRepetition() async {
        let text = "¿Qué música te gusta escuchar cuando estás en casa?"
        let reply = GeneratedAmigoReply(spanish: text, english: "What music do you like at home?", profileFacts: [])
        let generator = ScriptedAmigoGenerator([.success(reply), .success(reply)])
        await #expect(throws: OnDeviceChatError.repeatedReply) {
            try await OnDeviceSpanishChat(generator: generator).reply(to: "Ya te dije.",
                context: ChatContext(amigo: Amigo.catalogue[2], scenario: nil),
                history: [ChatMessage(role: .storyteller, text: text)])
        }
        #expect(await generator.calls == 2)
    }

    @Test("Summary commits with the reply, survives reopening, and rolls back on failed save")
    @MainActor
    func savedContinuity() async throws {
        let context = ChatContext(amigo: Amigo.catalogue[0], scenario: nil)
        let repository = MemoryConversationRepository(archive: PracticeArchive())
        let first = GeneratedAmigoReply(spanish: "El café de olla lleva canela.", english: "Café de olla contains cinnamon.",
            profileFacts: [], sessionRecap: "Café de olla explained.", suggestedActivity: true)
        let second = GeneratedAmigoReply(spanish: "También se prepara en una olla de barro.", english: "It is also made in a clay pot.",
            profileFacts: [], sessionRecap: "Clay pot discussed.")
        let generator = ScriptedAmigoGenerator([.success(first), .success(second)])
        let manager = ConversationManager(repository: repository, responder: OnDeviceSpanishChat(generator: generator))
        await manager.loadSavedPractice()
        try await manager.send("Cuéntame del café.", in: context)
        let saved = manager.conversation(for: context)
        #expect(saved.sessionSummary?.recap == first.sessionRecap)
        await repository.failNextSave()
        await #expect(throws: TestFailure.self) { try await manager.send("¿Cómo se prepara?", in: context) }
        #expect(manager.conversation(for: context) == saved)
        let reopened = ConversationManager(repository: repository, responder: StubSpanishChat(reply: .success("Hola")))
        await reopened.loadSavedPractice()
        #expect(reopened.conversation(for: context) == saved)
        #expect(reopened.conversation(for: ChatContext(amigo: Amigo.catalogue[1], scenario: nil)).sessionSummary == nil)
        let prompts = await generator.prompts
        #expect(prompts.last?.contains(first.sessionRecap) == true)
    }
}
