import Testing
@testable import Amigos

@Suite("Learner profile feature")
@MainActor
struct ProfileManagerTests {
    @Test("Explicit corrections update address without inferring sex and survive a reload")
    func remembersAddressCorrection() async throws {
        let repository = MemoryProfileRepository()
        let manager = ProfileManager(repository: repository)
        await manager.loadSavedProfile()
        _ = try await manager.remember([ProfileFact(field: .preferredAddress, value: "amigo", evidence: "amigo, no amiga")], from: "Soy amigo, no amiga")
        #expect(manager.profile.value(for: .preferredAddress) == "amigo")
        #expect(manager.profile.value(for: .sex).isEmpty)
        let reopened = ProfileManager(repository: repository)
        await reopened.loadSavedProfile()
        #expect(reopened.profile.value(for: .preferredAddress) == "amigo")
    }

    @Test("Facts need evidence from this message and can be corrected or forgotten")
    func evidenceAndCorrections() async throws {
        let manager = ProfileManager(repository: MemoryProfileRepository())
        await manager.loadSavedProfile()
        let ignored = try await manager.remember([ProfileFact(field: .firstName, value: "Ana", evidence: "Me llamo Ana")], from: "Hola")
        #expect(ignored.isEmpty)
        _ = try await manager.remember([ProfileFact(field: .firstName, value: "Matt", evidence: "Matt")], from: "Call me Matt")
        #expect(manager.profile.displayName == "Matt")
        _ = try await manager.remember([ProfileFact(field: .firstName, value: "Matthew", evidence: "Matthew")], from: "Actually, Matthew")
        #expect(manager.profile.value(for: .firstName) == "Matthew")
        _ = try await manager.remember([ProfileFact(field: .firstName, value: "", evidence: "Forget my first name")], from: "Forget my first name")
        #expect(manager.profile.value(for: .firstName).isEmpty)
        #expect(manager.profile.displayName == "You")
    }

    @Test("Invalid facts and failed writes do not change saved details")
    func rejectsInvalidFacts() async throws {
        let repository = MemoryProfileRepository()
        let manager = ProfileManager(repository: repository)
        await manager.loadSavedProfile()
        await #expect(throws: ProfileError.self) {
            try await manager.remember([ProfileFact(field: .age, value: "-5", evidence: "-5")], from: "I am -5")
        }
        await repository.failNextSave()
        await #expect(throws: TestFailure.self) {
            try await manager.remember([ProfileFact(field: .homeCountry, value: "Mexico", evidence: "Mexico")], from: "I am from Mexico")
        }
        #expect(manager.profile.details == nil)
    }

    @Test("Changing the display name retains conversational profile details")
    func preservesDetailsWhenRenaming() async throws {
        let manager = ProfileManager(repository: MemoryProfileRepository())
        await manager.loadSavedProfile()
        _ = try await manager.remember([ProfileFact(field: .favouriteColour, value: "Green", evidence: "Green")], from: "Green")
        try await manager.saveDisplayName("Sam")
        #expect(manager.profile.value(for: .favouriteColour) == "Green")
    }
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
