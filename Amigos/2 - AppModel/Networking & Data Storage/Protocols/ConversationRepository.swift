protocol ConversationRepository: Sendable {
    func load() async throws -> PracticeArchive?
    func save(_ archive: PracticeArchive) async throws
}
