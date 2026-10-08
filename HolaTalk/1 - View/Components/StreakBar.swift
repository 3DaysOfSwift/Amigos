import SwiftUI

struct StreakBar: View {
    @Environment(ThemeManager.self) private var themeManager
    let days: [PracticeDay]

    private var palette: AppPalette { themeManager.currentTheme.palette }

    var body: some View {
        HStack(spacing: 5) {
            ForEach(days) { day in
                Circle()
                    .fill(day.practiced ? palette.streak : palette.mutedText.opacity(day.today ? 0.65 : 0.35))
                    .frame(width: 7, height: 7)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(day.date.formatted(date: .complete, time: .omitted)): \(day.practiced ? "practised" : "not practised")")
            }
        }
    }
}
