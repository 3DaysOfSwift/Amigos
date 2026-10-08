import Foundation

struct LearnerProfile: Codable, Equatable, Sendable {
    var displayName: String = "You"
}

enum ProfileError: LocalizedError {
    case emptyName
    case nameTooLong
    case unavailable

    var errorDescription: String? {
        switch self {
        case .emptyName: "Enter a name for your profile."
        case .nameTooLong: "Keep your name under 25 characters."
        case .unavailable: "Your profile is not ready. Try opening it again before saving."
        }
    }
}
