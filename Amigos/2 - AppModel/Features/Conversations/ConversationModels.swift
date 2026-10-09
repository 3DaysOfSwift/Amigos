import Foundation

struct ChatMessage: Codable, Identifiable, Sendable, Equatable {
    enum Role: String, Codable, Sendable { case learner, storyteller }
    let id: UUID
    let role: Role
    let text: String
    let englishText: String?
    var startsNewConversation: Bool? = nil

    init(id: UUID = UUID(), role: Role, text: String, englishText: String? = nil) {
        self.id = id
        self.role = role
        self.text = text
        self.englishText = englishText
    }
}

struct SpanishChatReply: Sendable, Equatable {
    let spanish: String
    let english: String
    var profileFacts: [ProfileFact] = []
    var discardedProfileFactCount: Int = 0
}

struct Conversation: Codable, Sendable, Equatable {
    var lastGreetingDay: String? = nil
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
    let story: String
    let rememberedFor: String

    static let catalogue = [
        Amigo(
            id: "alma", name: "Alma",
            identity: "A playful skeleton photographer in Mexico City who notices the little things.",
            voice: "warm, observant and lightly funny; asks about ordinary moments in the learner's day",
            story: "Alma carried her camera everywhere. She loved the unplanned moments: a neighbour laughing, a patch of afternoon light, a friend who finally felt comfortable being seen. She still asks about the little things you noticed today.",
            rememberedFor: "Making ordinary days feel worth remembering."
        ),
        Amigo(
            id: "nico", name: "Nico",
            identity: "A cheerful skeleton home cook in Oaxaca who loves markets and good food.",
            voice: "easygoing and curious; talks about meals, ingredients and small plans without turning the chat into a lesson",
            story: "Nico believed a kitchen was never too small for one more friend. He wandered Oaxaca’s markets looking for something delicious, then cooked enough to share. Tell him what you ate, or what you wish you could make together.",
            rememberedFor: "Always saving someone a place at the table."
        ),
        Amigo(
            id: "ines", name: "Inés",
            identity: "A witty skeleton music lover in Guadalajara who always has a new song to share.",
            voice: "energetic and witty; chats about music, films and what the learner is enjoying lately",
            story: "Inés made playlists for every mood and insisted that the best songs were meant to be passed on. A melody could bring back a whole evening for her. She wants to know what you have been listening to—and why it matters to you.",
            rememberedFor: "Finding the right song for the right person."
        ),
        Amigo(
            id: "dani", name: "Dani",
            identity: "A friendly skeleton neighbour in Mérida who is always making weekend plans.",
            voice: "relaxed and encouraging; talks about places to go, daily errands and meeting up",
            story: "Dani knew every corner of Mérida and somehow always had time for one more walk. Even an ordinary errand could become an adventure with the right company. Ask where to go, or tell him about your own neighbourhood.",
            rememberedFor: "Turning a simple plan into a good memory."
        ),
        Amigo(
            id: "lucia", name: "Lucía",
            identity: "A daring skeleton skateboarder in Monterrey who collects the best shortcuts around town.",
            voice: "quick, confident and teasing; talks about music, street life and trying something new, but never pressures the learner",
            story: "Lucía learned the city from the wheels of her skateboard. She knew the shortcuts, the loud streets, and the quiet places where a friend could catch their breath. She will dare you to try something new, then cheer you on at your own pace.",
            rememberedFor: "Making courage feel contagious."
        ),
        Amigo(
            id: "rafa", name: "Rafa",
            identity: "A skeleton plant enthusiast in Puebla whose balcony is becoming a tiny jungle.",
            voice: "curious, dryly funny and gentle; chats about plants, pets, weather and small everyday discoveries",
            story: "Rafa’s balcony in Puebla slowly became a jungle. He could name every plant, but he was happiest when a cutting found a new home with a friend. Tell him what is growing around you, even if it is only an idea.",
            rememberedFor: "Helping small things grow."
        ),
        Amigo(
            id: "sol", name: "Sol",
            identity: "A dreamy skeleton stargazer in Guanajuato who takes late-night walks to look at the sky.",
            voice: "imaginative and thoughtful; talks about the night sky, hopes, odd dreams and what happened today",
            story: "Sol took long walks under the Guanajuato sky and asked questions nobody else thought to ask. She loved hearing people describe the futures they imagined for themselves. Tell her a dream, a worry, or what the stars looked like tonight.",
            rememberedFor: "Making room for impossible dreams."
        ),
        Amigo(
            id: "tavo", name: "Tavo",
            identity: "An enthusiastic skeleton amateur magician in Veracruz whose tricks almost work.",
            voice: "playful and theatrical without being loud; jokes about harmless failed magic tricks and asks the learner to guess what happens next",
            story: "Tavo practiced little magic tricks in Veracruz. Most went wrong; the stories afterward were even better. He never minded being the joke if it made a friend smile. Ask for a trick, or tell him about your most spectacular mistake.",
            rememberedFor: "The joy of trying again, especially when everyone laughed."
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
    var startsWithGreeting: Bool = false
    var id: String { scenario.map { "role-play:\($0.id)" } ?? "chat:\(amigo.id)" }
    var cost: Int { scenario == nil ? 0 : 2 }
    var title: String { scenario?.title ?? amigo.name }
}

struct PracticeArchive: Codable, Sendable {
    var introducedAmigoIDs: [String]? = nil
    var hasExplainedDoubloons: Bool? = nil
    var hasAnsweredNotificationInvitation: Bool? = nil
    var firstOpenedAt: Date? = nil
    var doubloons: Int = 10
    var conversations: [String: Conversation] = [:]
    var completedRolePlays: [String: Int] = [:]
    var dailyAmigoChatProgress: [String: DailyAmigoChatProgress]? = nil
    var typedWords: Set<String>? = nil
    var typedWordCount: Int? = nil
    var practiceDays: Set<String>? = nil
    var streakTimeZoneIdentifier: String? = nil
}

struct DailyAmigoInvitation: Sendable, Equatable {
    let amigo: Amigo
    let streak: Int
}

struct DailyAmigoChatProgress: Codable, Sendable, Equatable {
    let day: String
    var successfulExchanges: Int
    var awardedDoubloons: Int
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
    case emptyMessage, messageTooLong, messageNotFound, insufficientDoubloons, rolePlayNotAuthorized, unfinishedRolePlay, conversationFinished, responseInProgress

    var errorDescription: String? {
        switch self {
        case .emptyMessage: "Type a message in Spanish first."
        case .messageTooLong: "Keep your message under 500 characters."
        case .messageNotFound: "This message is no longer available to translate."
        case .insufficientDoubloons: "You need more doubloons to continue."
        case .rolePlayNotAuthorized: "Slide to start this Role Play first."
        case .unfinishedRolePlay: "Exchange a few more messages before finishing this Role Play."
        case .conversationFinished: "This Role Play is finished. Start it again to continue."
        case .responseInProgress: "Wait for the current reply."
        }
    }
}
