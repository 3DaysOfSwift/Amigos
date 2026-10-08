import Foundation
import Observation

@MainActor
@Observable
final class AmigoBioViewModel {
    private let conversations: any ConversationFeature

    init(conversations: any ConversationFeature = AppModel.shared.conversationsManager) {
        self.conversations = conversations
    }

    func messageCount(for amigo: Amigo) -> Int {
        conversations.messagesShared(with: amigo)
    }

    func messageCountDescription(for amigo: Amigo) -> String {
        let count = messageCount(for: amigo)
        return count == 1 ? "1 message shared" : "\(count) messages shared"
    }
}
