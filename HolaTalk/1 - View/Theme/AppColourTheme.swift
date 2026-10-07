import SwiftUI

enum AppColourTheme: String, CaseIterable, Identifiable {
    case midnight, daylight

    var id: String { rawValue }
    var name: String {
        switch self {
        case .midnight: "Midnight"
        case .daylight: "Daylight"
        }
    }
    var colourScheme: ColorScheme { self == .midnight ? .dark : .light }
    var palette: AppPalette {
        switch self {
        case .midnight:
            AppPalette(background: Color(red: 0.08, green: 0.10, blue: 0.14),
                       surface: Color(red: 0.13, green: 0.17, blue: 0.21),
                       learnerBubble: Color(red: 0.29, green: 0.33, blue: 0.40),
                       friendBubble: Color(red: 0.32, green: 0.40, blue: 0.37),
                       accent: Color(red: 0.63, green: 0.84, blue: 0.71),
                       mutedText: Color(red: 0.69, green: 0.74, blue: 0.76))
        case .daylight:
            AppPalette(background: Color(red: 0.96, green: 0.97, blue: 0.98),
                       surface: .white,
                       learnerBubble: Color(red: 0.86, green: 0.89, blue: 0.93),
                       friendBubble: Color(red: 0.80, green: 0.88, blue: 0.83),
                       accent: Color(red: 0.14, green: 0.42, blue: 0.33),
                       mutedText: Color(red: 0.35, green: 0.42, blue: 0.45))
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
}
