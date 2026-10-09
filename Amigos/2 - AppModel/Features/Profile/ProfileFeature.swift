import Foundation

@MainActor
protocol ProfileFeature: AnyObject {
    var profile: LearnerProfile { get }
    var loadError: String? { get }
    var isLoaded: Bool { get }
    func loadSavedProfile() async
    func saveDisplayName(_ name: String) async throws
    func saveProfile(displayName: String, details: [ProfileField: String]) async throws
    func remember(_ facts: [ProfileFact], from message: String) async throws -> [ProfileField]
}
