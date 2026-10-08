import SwiftUI

enum AppColourTheme: String, CaseIterable, Identifiable {
    case midnight, graphite, ocean, ember, daylight, sandstone, sage

    var id: String { rawValue }
    var name: String {
        switch self {
        case .midnight: "Midnight"
        case .graphite: "Graphite"
        case .ocean: "Ocean"
        case .ember: "Ember"
        case .daylight: "System Grey"
        case .sandstone: "Sandstone"
        case .sage: "Sage"
        }
    }
    var colourScheme: ColorScheme {
        switch self {
        case .midnight, .graphite, .ocean, .ember: .dark
        case .daylight, .sandstone, .sage: .light
        }
    }
    var palette: AppPalette {
        switch self {
        case .midnight:
            AppPalette(background: Color(red: 0.055, green: 0.065, blue: 0.082),
                       surface: Color(red: 0.12, green: 0.135, blue: 0.16),
                       learnerBubble: Color(red: 0.17, green: 0.21, blue: 0.28),
                       friendBubble: Color(red: 0.18, green: 0.22, blue: 0.20),
                       accent: Color(red: 1.00, green: 0.43, blue: 0.32),
                       mutedText: Color(red: 0.65, green: 0.68, blue: 0.75),
                       streak: Color(red: 1.00, green: 0.72, blue: 0.32),
                       unread: Color(red: 0.20, green: 0.57, blue: 1.00),
                       online: Color(red: 0.20, green: 0.82, blue: 0.58))
        case .graphite:
            AppPalette(background: Color(red: 0.105, green: 0.115, blue: 0.13),
                       surface: Color(red: 0.19, green: 0.20, blue: 0.23),
                       learnerBubble: Color(red: 0.27, green: 0.29, blue: 0.34),
                       friendBubble: Color(red: 0.22, green: 0.30, blue: 0.28),
                       accent: Color(red: 0.55, green: 0.86, blue: 0.72),
                       mutedText: Color(red: 0.72, green: 0.75, blue: 0.78),
                       streak: Color(red: 1.00, green: 0.73, blue: 0.39),
                       unread: Color(red: 0.40, green: 0.70, blue: 1.00),
                       online: Color(red: 0.35, green: 0.84, blue: 0.61))
        case .ocean:
            AppPalette(background: Color(red: 0.035, green: 0.11, blue: 0.17),
                       surface: Color(red: 0.09, green: 0.19, blue: 0.26),
                       learnerBubble: Color(red: 0.12, green: 0.30, blue: 0.42),
                       friendBubble: Color(red: 0.13, green: 0.33, blue: 0.33),
                       accent: Color(red: 0.48, green: 0.86, blue: 0.89),
                       mutedText: Color(red: 0.68, green: 0.78, blue: 0.82),
                       streak: Color(red: 1.00, green: 0.76, blue: 0.43),
                       unread: Color(red: 0.40, green: 0.69, blue: 1.00),
                       online: Color(red: 0.43, green: 0.88, blue: 0.70))
        case .ember:
            AppPalette(background: Color(red: 0.16, green: 0.09, blue: 0.10),
                       surface: Color(red: 0.25, green: 0.16, blue: 0.17),
                       learnerBubble: Color(red: 0.36, green: 0.22, blue: 0.22),
                       friendBubble: Color(red: 0.28, green: 0.27, blue: 0.21),
                       accent: Color(red: 1.00, green: 0.63, blue: 0.43),
                       mutedText: Color(red: 0.81, green: 0.72, blue: 0.72),
                       streak: Color(red: 1.00, green: 0.78, blue: 0.41),
                       unread: Color(red: 0.43, green: 0.70, blue: 1.00),
                       online: Color(red: 0.49, green: 0.83, blue: 0.61))
        case .daylight:
            AppPalette(background: Color(red: 0.92, green: 0.93, blue: 0.95),
                       surface: .white,
                       learnerBubble: Color(red: 0.81, green: 0.86, blue: 0.94),
                       friendBubble: Color(red: 0.79, green: 0.90, blue: 0.84),
                       accent: Color(red: 0.24, green: 0.43, blue: 0.70),
                       mutedText: Color(red: 0.36, green: 0.39, blue: 0.44),
                       streak: Color(red: 0.88, green: 0.48, blue: 0.12),
                       unread: Color(red: 0.10, green: 0.44, blue: 0.88),
                       online: Color(red: 0.08, green: 0.55, blue: 0.36))
        case .sandstone:
            AppPalette(background: Color(red: 0.96, green: 0.93, blue: 0.87),
                       surface: Color(red: 1.00, green: 0.99, blue: 0.96),
                       learnerBubble: Color(red: 0.88, green: 0.84, blue: 0.77),
                       friendBubble: Color(red: 0.83, green: 0.90, blue: 0.84),
                       accent: Color(red: 0.60, green: 0.29, blue: 0.16),
                       mutedText: Color(red: 0.40, green: 0.37, blue: 0.33),
                       streak: Color(red: 0.70, green: 0.37, blue: 0.11),
                       unread: Color(red: 0.13, green: 0.43, blue: 0.78),
                       online: Color(red: 0.17, green: 0.52, blue: 0.35))
        case .sage:
            AppPalette(background: Color(red: 0.88, green: 0.92, blue: 0.88),
                       surface: Color(red: 0.98, green: 0.99, blue: 0.96),
                       learnerBubble: Color(red: 0.81, green: 0.84, blue: 0.92),
                       friendBubble: Color(red: 0.72, green: 0.84, blue: 0.76),
                       accent: Color(red: 0.19, green: 0.42, blue: 0.32),
                       mutedText: Color(red: 0.34, green: 0.42, blue: 0.38),
                       streak: Color(red: 0.68, green: 0.42, blue: 0.15),
                       unread: Color(red: 0.13, green: 0.43, blue: 0.78),
                       online: Color(red: 0.12, green: 0.48, blue: 0.31))
        }
    }
}

struct AppPalette {
    let background: Color
    let surface: Color
    let learnerBubble: Color
    let friendBubble: Color
    let accent: Color
    let mutedText: Color
    let streak: Color
    let unread: Color
    let online: Color
}
