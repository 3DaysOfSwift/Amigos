import Testing
@testable import Amigos

@Suite("Learner profile feature")
@MainActor
struct ProfileManagerTests {
    @Test("A new learner starts as You and a saved name is restored")
    func saveAndRestoreName() async throws {
        let repository = MemoryProfileRepository()
        let first = ProfileManager(repository: repository)
        await first.loadSavedProfile()
        #expect(first.profile.displayName == "You")

        try await first.saveDisplayName("  Alex  ")
        #expect(first.profile.displayName == "Alex")

        let next = ProfileManager(repository: repository)
        await next.loadSavedProfile()
        #expect(next.profile.displayName == "Alex")
    }

    @Test("Invalid names do not replace the saved profile")
    func invalidNames() async {
        let repository = MemoryProfileRepository(profile: LearnerProfile(displayName: "Alex"))
        let manager = ProfileManager(repository: repository)
        await manager.loadSavedProfile()
        await #expect(throws: ProfileError.self) { try await manager.saveDisplayName("  ") }
        await #expect(throws: ProfileError.self) { try await manager.saveDisplayName(String(repeating: "A", count: 25)) }
        #expect(manager.profile.displayName == "Alex")
        #expect(await repository.storedProfile()?.displayName == "Alex")
    }

    @Test("A failed write retains the previous name")
    func failedSave() async {
        let repository = MemoryProfileRepository(profile: LearnerProfile(displayName: "Alex"))
        let manager = ProfileManager(repository: repository)
        await manager.loadSavedProfile()
        await repository.failNextSave()
        await #expect(throws: TestFailure.self) { try await manager.saveDisplayName("Sam") }
        #expect(manager.profile.displayName == "Alex")
        #expect(await repository.storedProfile()?.displayName == "Alex")
    }

    @Test("Unreadable saved profile is reported without replacing it")
    func failedLoad() async {
        let repository = MemoryProfileRepository(profile: LearnerProfile(displayName: "Alex"))
        await repository.failLoad()
        let manager = ProfileManager(repository: repository)
        await manager.loadSavedProfile()
        #expect(manager.loadError != nil)
        #expect(!manager.isLoaded)
        await #expect(throws: ProfileError.self) { try await manager.saveDisplayName("Sam") }
        #expect(await repository.storedProfile()?.displayName == "Alex")
    }
}
