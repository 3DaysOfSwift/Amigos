import Foundation

@MainActor
protocol ProfileFeature: AnyObject {
    var profile: LearnerProfile { get }
    var loadError: String? { get }
    var isLoaded: Bool { get }
    func loadSavedProfile() async
    func saveDisplayName(_ name: String) async throws
}
