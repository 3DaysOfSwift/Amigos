import Foundation
import Observation

@MainActor
@Observable
final class ProfileManager: ProfileFeature {
    private let repository: any ProfileRepository
    private(set) var profile = LearnerProfile()
    private(set) var loadError: String?
    private(set) var isLoaded = false

    init(repository: any ProfileRepository) {
        self.repository = repository
    }

    func loadSavedProfile() async {
        do {
            profile = try await repository.load() ?? LearnerProfile()
            loadError = nil
            isLoaded = true
        } catch {
            isLoaded = false
            loadError = "Your profile could not be opened: \(error.localizedDescription)"
        }
    }

    func saveDisplayName(_ name: String) async throws {
        guard isLoaded else { throw ProfileError.unavailable }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw ProfileError.emptyName }
        guard trimmed.count <= 24 else { throw ProfileError.nameTooLong }
        let updated = LearnerProfile(displayName: trimmed)
        try await repository.save(updated)
        profile = updated
    }
}
