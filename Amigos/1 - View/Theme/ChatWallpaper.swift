import Foundation

enum ChatWallpaper: String, CaseIterable, Identifiable {
    case plain, amigos, fiesta, tropical, study

    var id: String { rawValue }

    var name: String {
        switch self {
        case .plain: "Plain"
        case .amigos: "Amigos"
        case .fiesta: "Fiesta"
        case .tropical: "Tropical"
        case .study: "Study"
        }
    }

    var motifs: [ChatWallpaperMotif] {
        switch self {
        case .plain: []
        case .amigos: [.emoji("💀"), .emoji("🎸"), .emoji("🌼"), .emoji("☀️"), .emoji("🌴"), .sombrero, .emoji("👓"), .emoji("📚")]
        case .fiesta: [.emoji("💀"), .emoji("🎸"), .emoji("🌼"), .sombrero, .emoji("☀️")]
        case .tropical: [.emoji("🌴"), .emoji("☀️"), .emoji("🌼"), .emoji("✨")]
        case .study: [.emoji("📚"), .emoji("👓"), .emoji("✨"), .emoji("☀️")]
        }
    }
}

enum ChatWallpaperMotif: Hashable {
    case emoji(String)
    case sombrero
}
