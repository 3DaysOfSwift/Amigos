import SwiftUI

struct StreakBar: View {
    @Environment(ThemeManager.self) private var themeManager
    let days: [PracticeDay]

    private var palette: AppPalette { themeManager.currentTheme.palette }

    var body: some View {
        HStack(spacing: 8) {
            ForEach(days) { day in
                VStack(spacing: 5) {
                    Text(day.label)
                        .font(.caption2.weight(.semibold))
                    Image(systemName: day.practiced ? "checkmark.circle.fill" : day.today ? "circle.inset.filled" : "circle")
                        .font(.title3)
                        .opacity(day.practiced || day.today ? 1 : 0.45)
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(day.date.formatted(date: .complete, time: .omitted)): \(day.practiced ? "practised" : "not practised")")
            }
        }
        .foregroundStyle(palette.accent)
    }
}
