import Foundation
import Observation

@MainActor
@Observable
final class ProfileManager: ProfileFeature {
    private let repository: any ProfileRepository
    private var isSaving = false
    private(set) var profile = LearnerProfile()
    private(set) var loadError: String?
    private(set) var isLoaded = false

    init(repository: any ProfileRepository) {
        self.repository = repository
    }

    func loadSavedProfile() async {
        do {
            profile = try await repository.load() ?? LearnerProfile()
            loadError = nil
            isLoaded = true
        } catch {
            isLoaded = false
            loadError = "Your profile could not be opened: \(error.localizedDescription)"
        }
    }

    func saveDisplayName(_ name: String) async throws {
        try await saveProfile(displayName: name, details: profile.details ?? [:])
    }

    func saveProfile(displayName name: String, details: [ProfileField: String]) async throws {
        guard isLoaded else { throw ProfileError.unavailable }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw ProfileError.emptyName }
        guard trimmed.count <= 24 else { throw ProfileError.nameTooLong }
        var updated = profile
        updated.displayName = trimmed
        updated.details = try details.reduce(into: [:]) { result, entry in
            let value = try validated(entry.value, for: entry.key)
            if !value.isEmpty { result[entry.key] = value }
        }
        try await commit(updated)
    }

    func remember(_ facts: [ProfileFact], from message: String) async throws -> [ProfileField] {
        guard isLoaded else { throw ProfileError.unavailable }
        var updated = profile
        var details = profile.details ?? [:]
        var changed: [ProfileField] = []
        for fact in facts {
            let evidence = fact.evidence.trimmingCharacters(in: .whitespacesAndNewlines)
            guard evidence.count >= 2, message.localizedCaseInsensitiveContains(evidence) else { continue }
            let value = try validated(fact.value, for: fact.field)
            guard (details[fact.field] ?? "") != value else { continue }
            details[fact.field] = value.isEmpty ? nil : value
            if !changed.contains(fact.field) { changed.append(fact.field) }
        }
        guard !changed.isEmpty else { return [] }
        updated.details = details
        if changed.contains(.firstName) {
            let firstName = details[.firstName] ?? ""
            if profile.displayName == "You" || profile.displayName == profile.value(for: .firstName) {
                updated.displayName = firstName.isEmpty ? "You" : String(firstName.prefix(24))
            }
        }
        try await commit(updated)
        return changed
    }

    private func validated(_ raw: String, for field: ProfileField) throws -> String {
        let value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return "" }
        guard value.count <= 500 else { throw ProfileError.invalidDetail(field.title) }
        if field == .age {
            guard let age = Int(value), (0...120).contains(age) else { throw ProfileError.invalidDetail(field.title) }
        }
        if field == .preferredAddress {
            guard ["amigo", "amiga", "neutral"].contains(value) else { throw ProfileError.invalidDetail(field.title) }
        }
        if field == .dateOfBirth {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.calendar = Calendar(identifier: .gregorian)
            formatter.dateFormat = "yyyy-MM-dd"
            formatter.isLenient = false
            guard let date = formatter.date(from: value), formatter.string(from: date) == value,
                  date <= Date.now else { throw ProfileError.invalidDetail(field.title) }
        }
        return value
    }

    private func commit(_ updated: LearnerProfile) async throws {
        guard !isSaving else { throw ProfileError.saving }
        isSaving = true
        defer { isSaving = false }
        try await repository.save(updated)
        profile = updated
    }
}
