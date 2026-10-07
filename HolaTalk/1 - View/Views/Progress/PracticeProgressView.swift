import SwiftUI

struct PracticeProgressView: View {
    @Environment(ThemeManager.self) private var themeManager
    @State private var viewModel = PracticeProgressViewModel()
    @State private var showingWords = false

    private var palette: AppPalette { themeManager.currentTheme.palette }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                HStack(alignment: .center) {
                    Label("Amigos", systemImage: "bubble.left.and.bubble.right.fill")
                        .font(.title2.bold())
                        .foregroundStyle(palette.accent)
                    Spacer()
                    HStack(spacing: 6) {
                        DoubloonIcon(size: 24)
                        Text("\(viewModel.doubloons)")
                    }
                        .font(.headline)
                        .accessibilityLabel("\(viewModel.doubloons) doubloons")
                }

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

                    Text(showingWords ? "Your words" : "Your streak")
                        .font(.system(.largeTitle, design: .serif))

                    Text(showingWords ? "\(viewModel.uniqueWordCount) words" : "\(viewModel.currentStreak) days")
                        .font(.system(size: 58, weight: .bold, design: .rounded))
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                        .foregroundStyle(showingWords ? palette.accent : .yellow)

                    Text(showingWords
                         ? "\(viewModel.typedWordCount) words typed across your Spanish conversations."
                         : (viewModel.practicedToday
                            ? "You have already practised today. Come back for another conversation."
                            : "One real conversation keeps it going today."))
                        .font(.body)
                        .foregroundStyle(palette.mutedText)

                    Button(showingWords ? "Show streak" : "Show words") {
                        showingWords.toggle()
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(palette.accent)
                    .padding(.top, 4)
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
        .navigationTitle("Your progress")
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
                        .foregroundStyle(day.today ? themeManager.currentTheme.palette.accent : themeManager.currentTheme.palette.mutedText)
                    Image(systemName: day.practiced ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundStyle(day.practiced ? themeManager.currentTheme.palette.accent : themeManager.currentTheme.palette.mutedText)
                        .frame(maxWidth: .infinity)
                }
                .accessibilityElement(children: .combine)
            }
        }
    }
}
