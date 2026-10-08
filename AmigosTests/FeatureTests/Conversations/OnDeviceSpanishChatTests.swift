import Testing
@testable import Amigos

@Suite("On-device Amigo response contract")
struct OnDeviceSpanishChatTests {
    private let context = ChatContext(amigo: Amigo.catalogue[3], scenario: nil)

    @Test("A normal short reply is accepted")
    func acceptsNaturalReply() {
        let reply = SpanishChatReply(
            spanish: "¡Claro! Ana vive cerca del centro. ¿Quieres que vayamos juntos?",
            english: "Of course! Ana lives near the centre. Do you want us to go together?"
        )
        #expect(OnDeviceSpanishChat().isSafe(reply, for: context))
    }

    @Test("A response containing a transcript speaker label is rejected")
    func rejectsTranscriptResponse() {
        let reply = SpanishChatReply(
            spanish: "Learner: Hola\nDani: ¡Hola! ¿Cómo estás?",
            english: "Learner: Hello\nDani: Hi! How are you?"
        )
        #expect(!OnDeviceSpanishChat().isSafe(reply, for: context))
    }
}
