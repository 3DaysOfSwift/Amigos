import Foundation
import Observation

@MainActor
@Observable
final class RolePlayAdmissionViewModel {
    private(set) var confirmed = false

    func finish(translation: CGFloat, travel: CGFloat, rightToLeft: Bool, confirm: () -> Bool) {
        let movement = rightToLeft ? -translation : translation
        guard travel > 0, movement >= travel * 0.92 else { return }
        activate(confirm: confirm)
    }

    func activate(confirm: () -> Bool) {
        guard !confirmed else { return }
        confirmed = confirm()
    }
}
