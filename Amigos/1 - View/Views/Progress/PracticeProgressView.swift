import SwiftUI

struct PracticeProgressView: View {
    @Environment(ThemeManager.self) private var themeManager
    @State private var viewModel = PracticeProgressViewModel()

    private var palette: AppPalette { themeManager.currentTheme.palette }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                HStack(alignment: .center) {
                    AmigosWordmark(fontSize: 27)
                    Spacer()
                    HStack(spacing: 6) {
                        DoubloonIcon(size: 24)
                        Text("\(viewModel.doubloons)")
                    }
                        .font(.headline)
                        .accessibilityLabel("\(viewModel.doubloons) doubloons")
                }

                VStack(alignment: .leading, spacing: 7) {
                    Text("CURRENT DAY STREAK")
                        .font(.caption.weight(.bold))
                        .tracking(1.8)
                        .foregroundStyle(palette.mutedText)
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        Text("\(viewModel.currentStreak)")
                            .font(.system(size: 112, weight: .bold, design: .rounded))
                            .minimumScaleFactor(0.55)
                            .lineLimit(1)
                            .monospacedDigit()
                            .foregroundStyle(palette.streak)
                        Text(viewModel.currentStreak == 1 ? "day" : "days")
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(palette.mutedText)
                    }
                    Text(viewModel.practicedToday
                         ? "You have already practised today. Keep the conversation going."
                         : "One real conversation keeps your streak going today.")
                        .foregroundStyle(palette.mutedText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 20) {
                    Text("Your week")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(palette.mutedText)
                    WeeklyCalendar(days: viewModel.currentWeek)
                }
                .padding(22)
                .background(palette.surface, in: RoundedRectangle(cornerRadius: 26))

                VStack(alignment: .leading, spacing: 8) {
                    Text("Days since you joined Amigos")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(palette.mutedText)
                    Text("\(viewModel.daysSinceFirstUse)")
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .monospacedDigit()
                        .foregroundStyle(palette.accent)
                }
                .padding(22)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(palette.surface, in: RoundedRectangle(cornerRadius: 26))

                VStack(alignment: .leading, spacing: 20) {
                    Label("A little Spanish, every day", systemImage: "sparkle")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(palette.accent)

                    Text("Spanish words used")
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))

                    Text("\(viewModel.typedWordCount)")
                        .font(.system(size: 58, weight: .bold, design: .rounded))
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                        .foregroundStyle(palette.accent)

                    Text("Words typed across your Spanish conversations. \(viewModel.uniqueWordCount) different words used so far.")
                        .font(.body)
                        .foregroundStyle(palette.mutedText)
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(palette.surface, in: RoundedRectangle(cornerRadius: 28))

                Text("Your progress grows through the conversations you have in Spanish.")
                    .foregroundStyle(palette.mutedText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(24)
        }
        .navigationTitle("Day Streak")
        .background(palette.background.ignoresSafeArea())
    }
}

private struct WeeklyCalendar: View {
    @Environment(ThemeManager.self) private var themeManager
    let days: [PracticeDay]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(days) { day in
                VStack(spacing: 12) {
                    Text(day.label)
                        .font(.caption.weight(day.today ? .bold : .medium))
                        .foregroundStyle(day.today ? themeManager.currentTheme.palette.streak : themeManager.currentTheme.palette.mutedText)
                    Image(systemName: day.practiced ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundStyle(day.practiced ? themeManager.currentTheme.palette.streak : themeManager.currentTheme.palette.mutedText)
                        .frame(maxWidth: .infinity)
                }
                .accessibilityElement(children: .combine)
            }
        }
    }
}
