import Foundation

protocol ProfileRepository: Sendable {
    func load() async throws -> LearnerProfile?
    func save(_ profile: LearnerProfile) async throws
}
