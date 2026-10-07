import Foundation

struct ChatMessage: Codable, Identifiable, Sendable, Equatable {
    enum Role: String, Codable, Sendable { case learner, storyteller }
    let id: UUID
    let role: Role
    let text: String

    init(id: UUID = UUID(), role: Role, text: String) {
        self.id = id
        self.role = role
        self.text = text
    }
}

struct Conversation: Codable, Sendable, Equatable {
    var messages: [ChatMessage] = []
    var paidAt: Date? = nil
    var finished = false

    func canContinue(until date: Date) -> Bool {
        guard !finished, let paidAt else { return false }
        return date.timeIntervalSince(paidAt) < 10 * 60
    }
}

struct Amigo: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let identity: String
    let voice: String

    static let firstFriend = Amigo(
        id: "alma", name: "Alma",
        identity: "A photographer in Mexico City who notices the little things.",
        voice: "warm, observant and lightly funny; asks about ordinary moments in the learner's day"
    )

    static let catalogue = [
        firstFriend,
        Amigo(
            id: "nico", name: "Nico",
            identity: "A home cook in Oaxaca who loves markets and good food.",
            voice: "easygoing and curious; talks about meals, ingredients and small plans without turning the chat into a lesson"
        ),
        Amigo(
            id: "ines", name: "Inés",
            identity: "A music lover in Guadalajara who always has a new song to share.",
            voice: "energetic and witty; chats about music, films and what the learner is enjoying lately"
        ),
        Amigo(
            id: "dani", name: "Dani",
            identity: "A friendly neighbour in Mérida who is always making weekend plans.",
            voice: "relaxed and encouraging; talks about places to go, daily errands and meeting up"
        )
    ]
}

struct RolePlayScenario: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let symbol: String
    let context: String
    let learnerRole: String
    let aiRole: String
    let objective: String

    static let catalogue = [
        RolePlayScenario(id: "coffee", title: "Order a Coffee", symbol: "cup.and.saucer.fill", context: "a café in Mexico", learnerRole: "customer", aiRole: "friendly barista", objective: "Order a drink and handle the usual café questions."),
        RolePlayScenario(id: "tacos", title: "Order Tacos", symbol: "takeoutbag.and.cup.and.straw.fill", context: "a taquería in Mexico", learnerRole: "customer", aiRole: "taquero", objective: "Order food and make simple choices."),
        RolePlayScenario(id: "bar", title: "Order at a Bar", symbol: "wineglass.fill", context: "a bar in Mexico", learnerRole: "customer", aiRole: "bartender", objective: "Order a drink and respond naturally."),
        RolePlayScenario(id: "taxi", title: "Talk to a Driver", symbol: "car.fill", context: "an Uber in Mexico", learnerRole: "passenger", aiRole: "driver", objective: "Confirm the destination and make the journey clear."),
        RolePlayScenario(id: "pharmacy", title: "Visit a Pharmacy", symbol: "cross.case.fill", context: "a pharmacy in Mexico", learnerRole: "customer", aiRole: "pharmacist", objective: "Explain what you need and understand follow-up questions."),
        RolePlayScenario(id: "haircut", title: "Get a Haircut", symbol: "scissors", context: "a salon in Mexico", learnerRole: "customer", aiRole: "hairdresser", objective: "Describe a haircut and agree the details."),
        RolePlayScenario(id: "shop", title: "Buy Something", symbol: "bag.fill", context: "a shop in Mexico", learnerRole: "customer", aiRole: "shop assistant", objective: "Find, choose and pay for an item."),
        RolePlayScenario(id: "delivery", title: "Receive a Delivery", symbol: "shippingbox.fill", context: "an apartment building in Mexico", learnerRole: "resident", aiRole: "delivery driver", objective: "Find the delivery and give clear instructions."),
        RolePlayScenario(id: "landlord", title: "Talk to a Landlord", symbol: "house.fill", context: "a rented apartment in Mexico", learnerRole: "tenant", aiRole: "landlord", objective: "Describe a practical issue and arrange a solution."),
        RolePlayScenario(id: "neighbour", title: "Meet a Neighbour", symbol: "person.2.fill", context: "your neighbourhood in Mexico", learnerRole: "new neighbour", aiRole: "neighbour", objective: "Introduce yourself and make a friendly connection."),
        RolePlayScenario(id: "restaurant", title: "Eat at a Restaurant", symbol: "fork.knife", context: "a restaurant in Mexico", learnerRole: "guest", aiRole: "server", objective: "Order a meal and handle the meal naturally."),
        RolePlayScenario(id: "directions", title: "Ask for Directions", symbol: "map.fill", context: "a street in Mexico", learnerRole: "visitor", aiRole: "local person", objective: "Ask for and understand directions.")
    ]
}

struct ChatContext: Hashable, Sendable {
    let amigo: Amigo
    let scenario: RolePlayScenario?
    var id: String { scenario.map { "role-play:\($0.id)" } ?? "chat:\(amigo.id)" }
    var cost: Int { scenario == nil ? 1 : 2 }
    var title: String { scenario?.title ?? amigo.name }
}

struct PracticeArchive: Codable, Sendable {
    var firstOpenedAt: Date? = nil
    var doubloons: Int = 10
    var conversations: [String: Conversation] = [:]
    var completedRolePlays: [String: Int] = [:]
    var lastDailyChatRewardDay: String? = nil
    var typedWords: Set<String>? = nil
    var typedWordCount: Int? = nil
    var practiceDays: Set<String>? = nil
}

struct PracticeDay: Identifiable {
    let date: Date
    let practiced: Bool
    let today: Bool
    var id: Date { date }
    var label: String { date.formatted(.dateTime.weekday(.narrow)) }
}

struct RolePlayOption: Identifiable {
    let context: ChatContext
    let isUnlocked: Bool
    let completionCount: Int
    var id: String { context.id }
    var scenario: RolePlayScenario? { context.scenario }
}

enum ConversationError: LocalizedError {
    case emptyMessage, messageTooLong, insufficientDoubloons, unfinishedRolePlay, conversationFinished, responseInProgress

    var errorDescription: String? {
        switch self {
        case .emptyMessage: "Type a message in Spanish first."
        case .messageTooLong: "Keep your message under 500 characters."
        case .insufficientDoubloons: "You need more doubloons to continue."
        case .unfinishedRolePlay: "Exchange a few more messages before finishing this Role Play."
        case .conversationFinished: "This Role Play is finished. Start it again to continue."
        case .responseInProgress: "Wait for the current reply."
        }
    }
}
