import Foundation
@testable import HolaTalk

actor MemoryProfileRepository: ProfileRepository {
    private var savedProfile: LearnerProfile?
    private var shouldFailSave = false
    private var shouldFailLoad = false
    private(set) var loadCount = 0

    init(profile: LearnerProfile? = nil) {
        savedProfile = profile
    }

    func load() throws -> LearnerProfile? {
        loadCount += 1
        if shouldFailLoad { throw TestFailure.unavailable }
        return savedProfile
    }

    func save(_ profile: LearnerProfile) throws {
        if shouldFailSave {
            shouldFailSave = false
            throw TestFailure.unavailable
        }
        savedProfile = profile
    }

    func storedProfile() -> LearnerProfile? { savedProfile }
    func failNextSave() { shouldFailSave = true }
    func failLoad() { shouldFailLoad = true }
}
