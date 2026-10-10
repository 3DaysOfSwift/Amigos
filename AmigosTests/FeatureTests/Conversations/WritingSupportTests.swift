import Foundation
import Testing
@testable import Amigos

@Suite("Bilingual writing support")
struct WritingSupportTests {
    private let context = ChatContext(amigo: Amigo.catalogue[0], scenario: nil)

    @Test("Cancelled learning cannot publish late results or block the next exchange", .timeLimit(.minutes(1)))
    @MainActor
    func cancelledLearning() async throws {
        let gate = SuspendedSpanishChat()
        let feature = ConversationManager(repository: MemoryConversationRepository(archive: PracticeArchive()),
                                          responder: PausedLearningChat(gate: gate))
        await feature.loadSavedPractice()
        try await feature.send("Hola", in: context)
        let before = feature.conversation(for: context)
        let task = Task { try await feature.prepareLearningHelp(in: context) }
        await gate.waitUntilStarted()
        #expect(!feature.isResponding)
        await #expect(throws: ConversationError.responseInProgress) { try await feature.send("Bien", in: context) }
        task.cancel()
        await gate.complete(with: "Late help")
        await #expect(throws: CancellationError.self) { try await task.value }
        #expect(feature.conversation(for: context) == before)
        try await feature.send("Bien", in: context)
        #expect(feature.conversation(for: context).messages.count == before.messages.count + 2)
    }

    @Test("Learning help is requested on demand, cached and does not change rewards")
    @MainActor
    func onDemandCache() async throws {
        let answer = GeneratedAmigoReply(spanish: "Bien, gracias.", english: "Well, thanks.", profileFacts: [])
        let help = GeneratedAmigoReply(spanish: "", english: "", profileFacts: [],
            writingHelpKind: "correction", writingSuggestions: [GeneratedWritingSuggestion(
                spanish: "¿Cómo estás?", english: "How are you?", explanation: "Accents and question marks.")],
            suggestedReplies: [GeneratedSuggestedReply(spanish: "Me alegro.", english: "I'm glad.")])
        let generator = ScriptedAmigoGenerator([.success(answer), .success(help), .success(help)])
        let repository = MemoryConversationRepository(archive: PracticeArchive())
        let feature = ConversationManager(repository: repository, responder: OnDeviceSpanishChat(generator: generator))
        await feature.loadSavedPractice()
        try await feature.send("como estas", in: context)
        #expect(await generator.calls == 1)
        let original = feature.conversation(for: context)
        await repository.failNextSave()
        await #expect(throws: TestFailure.self) { try await feature.prepareLearningHelp(in: context) }
        #expect(feature.conversation(for: context) == original)
        try await feature.prepareLearningHelp(in: context)
        try await feature.prepareLearningHelp(in: context)
        #expect(await generator.purposes == [.reply, .learning, .learning])
        let saved = try #require(await repository.savedArchive())
        let chat = feature.conversation(for: context)
        #expect(chat.messages.map(\.text) == original.messages.map(\.text))
        #expect(chat.messages.first?.writingHelp?.suggestions.first?.spanish == "¿Cómo estás?")
        #expect(chat.messages.last?.suggestedReplies?.first?.spanish == "Me alegro.")
        #expect(chat.messages.last?.learningHelpPrepared == true)
        #expect(saved.dailyAmigoChatProgress?[context.amigo.id]?.successfulExchanges == 1)
        #expect(feature.doubloons == 10)
    }

    @Test("Polished accents and punctuation survive validation and persistence")
    @MainActor
    func correction() async throws {
        let generated = GeneratedAmigoReply(spanish: "Estoy bien, gracias.", english: "I'm well, thanks.", profileFacts: [],
            writingHelpKind: "correction", writingSuggestions: [GeneratedWritingSuggestion(
                spanish: "Hola, ¿cómo estás?", english: "Hello, how are you?", explanation: "Use ¿? and accents in cómo and estás.")])
        let generator = ScriptedAmigoGenerator([.success(generated)])
        let repository = MemoryConversationRepository(archive: PracticeArchive())
        let feature = ConversationManager(repository: repository, responder: OnDeviceSpanishChat(generator: generator))
        await feature.loadSavedPractice()
        try await feature.send("hola como estas", in: context)
        let before = feature.conversation(for: context)
        let message = try #require(before.messages.first)
        let suggestion = try #require(message.writingHelp?.suggestions.first)
        let wallet = feature.doubloons
        try await feature.acceptWritingSuggestion(suggestion, messageID: message.id, in: context)
        let after = feature.conversation(for: context)
        #expect(after.messages.first?.text == "Hola, ¿cómo estás?")
        #expect(after.messages.first?.originalText == "hola como estas")
        #expect(after.messages.first?.englishText == "Hello, how are you?")
        #expect(after.messages.first?.writingHelp == nil)
        #expect(after.messages.last == before.messages.last)
        #expect(feature.doubloons == wallet)
        #expect(await generator.calls == 1)
        await #expect(throws: ConversationError.self) {
            try await feature.acceptWritingSuggestion(suggestion, messageID: message.id, in: context)
        }
        let saved = try #require(await repository.savedArchive())
        #expect(saved.conversations[context.id] == after)
        #expect(saved.dailyAmigoChatProgress?[context.amigo.id]?.successfulExchanges == 1)
    }

    @Test("Clarification replacement rolls back on failed save and never counts twice")
    @MainActor
    func clarificationRollback() async throws {
        let question = GeneratedAmigoReply(spanish: "¿Quieres decir que estás cansado?", english: "Do you mean you are tired?", profileFacts: [],
            writingHelpKind: "clarification", writingSuggestions: [GeneratedWritingSuggestion(
                spanish: "Estoy cansado.", english: "I'm tired.", explanation: "Estar describes how you feel.")])
        let answer = GeneratedAmigoReply(spanish: "Vaya, ¿dormiste poco?", english: "Oh, did you sleep little?", profileFacts: [])
        let generator = ScriptedAmigoGenerator([.success(question), .success(answer), .success(answer)])
        let repository = MemoryConversationRepository(archive: PracticeArchive())
        let feature = ConversationManager(repository: repository, responder: OnDeviceSpanishChat(generator: generator))
        await feature.loadSavedPractice()
        try await feature.send("soy cans thing", in: context)
        let original = feature.conversation(for: context)
        let message = try #require(original.messages.first)
        let suggestion = try #require(message.writingHelp?.suggestions.first)
        await repository.failNextSave()
        await #expect(throws: TestFailure.self) {
            try await feature.acceptWritingSuggestion(suggestion, messageID: message.id, in: context)
        }
        #expect(feature.conversation(for: context) == original)
        try await feature.acceptWritingSuggestion(suggestion, messageID: message.id, in: context)
        let revised = feature.conversation(for: context)
        #expect(revised.messages.count == original.messages.count)
        #expect(revised.messages[1].text == answer.spanish)
        let saved = try #require(await repository.savedArchive())
        #expect(saved.dailyAmigoChatProgress?[context.amigo.id]?.successfulExchanges == 1)
        #expect(saved.doubloons == 10)
        #expect(await generator.calls == 3)
    }

    @Test("Accepting a clarification never charges Role Play twice")
    @MainActor
    func rolePlayDoesNotChargeAgain() async throws {
        let context = ChatContext(amigo: Amigo.catalogue[0], scenario: RolePlayScenario.catalogue[0])
        let question = GeneratedAmigoReply(spanish: "¿Quieres un café?", english: "Would you like a coffee?", profileFacts: [],
            writingHelpKind: "clarification", writingSuggestions: [GeneratedWritingSuggestion(
                spanish: "Quisiera un café.", english: "I'd like a coffee.", explanation: "Café has an accent on é.")])
        let answer = GeneratedAmigoReply(spanish: "¿Lo prefieres con leche?", english: "Would you prefer it with milk?", profileFacts: [])
        let feature = ConversationManager(repository: MemoryConversationRepository(archive: PracticeArchive()),
            responder: OnDeviceSpanishChat(generator: ScriptedAmigoGenerator([.success(question), .success(answer)])))
        await feature.loadSavedPractice()
        #expect(feature.authorizeRolePlay(context))
        try await feature.send("cafe thing", in: context)
        let message = try #require(feature.conversation(for: context).messages.first)
        let suggestion = try #require(message.writingHelp?.suggestions.first)
        let paidAt = feature.conversation(for: context).paidAt
        #expect(feature.doubloons == 8)
        try await feature.acceptWritingSuggestion(suggestion, messageID: message.id, in: context)
        #expect(feature.doubloons == 8)
        #expect(feature.conversation(for: context).paidAt == paidAt)
    }

    @Test("Invalid optional suggestions do not discard a valid reply")
    func invalidSuggestion() throws {
        let generated = GeneratedAmigoReply(spanish: "¿Puedes explicarlo?", english: "Can you explain?", profileFacts: [],
            writingHelpKind: "clarification", writingSuggestions: [GeneratedWritingSuggestion(spanish: "", english: "", explanation: "")])
        let reply = try OnDeviceSpanishChat(generator: ScriptedAmigoGenerator([])).validate(generated, for: context, latestMessage: "algo")
        #expect(reply.writingHelp == nil)
        #expect(reply.spanish == generated.spanish)
    }
}
