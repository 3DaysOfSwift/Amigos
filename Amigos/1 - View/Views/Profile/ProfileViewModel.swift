import Foundation
import Observation

@MainActor
@Observable
final class ProfileViewModel {
    private let profileFeature: any ProfileFeature
    var draftName: String
    var draftDetails: [ProfileField: String]
    private(set) var isSaving = false
    private(set) var error: String?
    private(set) var didSave = false
    var loadError: String? { profileFeature.loadError }
    var canSave: Bool { profileFeature.isLoaded && !isSaving }

    init(profileFeature: any ProfileFeature = AppModel.shared.profileManager) {
        self.profileFeature = profileFeature
        draftName = profileFeature.profile.displayName
        draftDetails = profileFeature.profile.details ?? [:]
    }

    func retryLoading() async {
        await profileFeature.loadSavedProfile()
        if profileFeature.isLoaded {
            draftName = profileFeature.profile.displayName
            draftDetails = profileFeature.profile.details ?? [:]
            error = nil
        }
    }

    func save() async {
        guard !isSaving else { return }
        isSaving = true
        error = nil
        didSave = false
        defer { isSaving = false }

        do {
            try await profileFeature.saveProfile(displayName: draftName, details: draftDetails)
            draftName = profileFeature.profile.displayName
            draftDetails = profileFeature.profile.details ?? [:]
            didSave = true
        } catch {
            self.error = error.localizedDescription
        }
    }
}
