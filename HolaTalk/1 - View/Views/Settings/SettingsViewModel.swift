import Foundation
import Observation

@MainActor
@Observable
final class SettingsViewModel {
    private let profileFeature: any ProfileFeature

    init(profileFeature: any ProfileFeature = AppModel.shared.profileManager) {
        self.profileFeature = profileFeature
    }

    var displayName: String { profileFeature.profile.displayName }

    var appVersion: String {
        guard let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
              let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String else {
            return "Version unavailable"
        }
        return "Version \(version) (\(build))"
    }
}
