import Testing
@testable import Amigos

@Suite("Role Play admission slider")
@MainActor
struct RolePlayAdmissionViewModelTests {
    @Test("A short slide does not confirm")
    func shortSlide() {
        let model = RolePlayAdmissionViewModel()
        var calls = 0
        model.finish(translation: 91, travel: 100, rightToLeft: false) { calls += 1; return true }
        #expect(calls == 0)
        #expect(!model.confirmed)
    }

    @Test("A complete slide confirms only once")
    func completeSlide() {
        let model = RolePlayAdmissionViewModel()
        var calls = 0
        model.finish(translation: 92, travel: 100, rightToLeft: false) { calls += 1; return true }
        model.activate { calls += 1; return true }
        #expect(calls == 1)
        #expect(model.confirmed)
    }

    @Test("Right-to-left slides move in the opposite direction")
    func rightToLeft() {
        let model = RolePlayAdmissionViewModel()
        model.finish(translation: -95, travel: 100, rightToLeft: true) { true }
        #expect(model.confirmed)
    }

    @Test("Rejected admission remains available for another attempt")
    func rejectedAdmission() {
        let model = RolePlayAdmissionViewModel()
        model.activate { false }
        #expect(!model.confirmed)
        model.activate { true }
        #expect(model.confirmed)
    }
}
