import Foundation
import Testing
@testable import HolaTalk

@Suite("Amigo bio screen")
@MainActor
struct AmigoBioViewModelTests {
    @Test("Every amigo has a distinct story and memory")
    func catalogueStories() {
        let amigos = Amigo.catalogue
        #expect(Set(amigos.map(\.id)).count == amigos.count)
        #expect(Set(amigos.map(\.story)).count == amigos.count)
        #expect(amigos.allSatisfy { !$0.story.isEmpty && !$0.rememberedFor.isEmpty })
    }

    @Test("Message count reflects only this amigo's learner messages")
    func messageCount() async {
        let alma = Amigo.catalogue[0]
        let nico = Amigo.catalogue[1]
        var archive = PracticeArchive()
        archive.conversations[ChatContext(amigo: alma, scenario: nil).id] = Conversation(messages: [
            ChatMessage(role: .learner, text: "Hola"),
            ChatMessage(role: .storyteller, text: "¡Hola!"),
            ChatMessage(role: .learner, text: "¿Cómo estás?")
        ])
        archive.conversations[ChatContext(amigo: nico, scenario: nil).id] = Conversation(messages: [
            ChatMessage(role: .learner, text: "Buenas")
        ])
        let manager = await makeTestConversationManager(archive: archive)
        let viewModel = AmigoBioViewModel(conversations: manager)

        #expect(viewModel.messageCountDescription(for: alma) == "2 messages shared")
        #expect(viewModel.messageCountDescription(for: nico) == "1 message shared")
        #expect(viewModel.messageCountDescription(for: Amigo.catalogue[2]) == "0 messages shared")
    }
}
