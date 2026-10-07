import Foundation
import Observation

@MainActor
@Observable
final class SettingsViewModel {
    var appVersion: String {
        guard let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
              let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String else {
            return "Version unavailable"
        }
        return "Version \(version) (\(build))"
    }
}
