import Foundation

struct LearnerProfile: Codable, Equatable, Sendable {
    var displayName: String = "You"
    var details: [ProfileField: String]? = nil

    func value(for field: ProfileField) -> String { details?[field] ?? "" }

    var conversationContext: String {
        ProfileField.allCases.compactMap { field in
            let value = value(for: field)
            return value.isEmpty ? nil : "\(field.rawValue): \(value)"
        }.joined(separator: "\n")
    }
}

enum ProfileField: String, Codable, CaseIterable, Identifiable, Sendable {
    case preferredAddress, sex, firstName, middleName, lastName, age, dateOfBirth
    case favouriteColour, visitedCountries, education, homeCountry, referralSource

    var id: String { rawValue }
    var title: String {
        switch self {
        case .preferredAddress: "How amigos address you"
        case .sex: "Sex (optional)"
        case .firstName: "First name"
        case .middleName: "Middle name"
        case .lastName: "Last name"
        case .age: "Age"
        case .dateOfBirth: "Date of birth (YYYY-MM-DD)"
        case .favouriteColour: "Favourite colour"
        case .visitedCountries: "Countries visited"
        case .education: "Education"
        case .homeCountry: "Home country"
        case .referralSource: "How you heard about Amigos"
        }
    }
}

struct ProfileFact: Codable, Equatable, Sendable {
    let field: ProfileField
    let value: String
    let evidence: String
}

enum ProfileError: LocalizedError {
    case emptyName
    case nameTooLong
    case unavailable
    case invalidDetail(String)
    case saving

    var errorDescription: String? {
        switch self {
        case .emptyName: "Enter a name for your profile."
        case .nameTooLong: "Keep your name under 25 characters."
        case .unavailable: "Your profile is not ready. Try opening it again before saving."
        case .invalidDetail(let title): "Check your \(title.lowercased())."
        case .saving: "Your profile is being saved. Please try again."
        }
    }
}
