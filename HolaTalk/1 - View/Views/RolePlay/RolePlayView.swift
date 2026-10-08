import SwiftUI

struct RolePlayView: View {
    @Environment(ThemeManager.self) private var themeManager
    @State private var viewModel = RolePlayViewModel()

    private var palette: AppPalette { themeManager.currentTheme.palette }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Label("SPECIAL PRACTICE", systemImage: "theatermasks.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(palette.accent)

                Text("Practise what happens next.")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))

                Text("Choose a familiar situation. Every conversation unfolds differently as you write in Spanish.")
                    .foregroundStyle(palette.mutedText)

                HStack(spacing: 10) {
                    DoubloonIcon(size: 26)
                    Text("\(viewModel.doubloons) doubloons")
                        .fontWeight(.semibold)
                    Spacer()
                    Text("2 per role play")
                        .foregroundStyle(palette.mutedText)
                }
                .font(.subheadline)
                .padding(18)
                .background(palette.surface, in: RoundedRectangle(cornerRadius: 20))

                LazyVStack(spacing: 14) {
                    ForEach(viewModel.options) { option in
                        if option.isUnlocked {
                            NavigationLink { ChatView(context: option.context) } label: {
                                RolePlayCell(option: option)
                            }
                            .buttonStyle(.plain)
                        } else {
                            RolePlayCell(option: option)
                        }
                    }
                }
            }
            .padding(22)
        }
        .navigationTitle("Role Play")
        .background(palette.background.ignoresSafeArea())
    }
}

private struct RolePlayCell: View {
    @Environment(ThemeManager.self) private var themeManager
    let option: RolePlayOption

    private var palette: AppPalette { themeManager.currentTheme.palette }

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            AmigoPortrait(amigo: option.context.amigo, size: 52)

            VStack(alignment: .leading, spacing: 7) {
                Text(option.context.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                if let scenario = option.scenario {
                    Text(scenario.context.capitalized)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(palette.accent)
                    Text(scenario.objective)
                        .font(.subheadline)
                        .foregroundStyle(palette.mutedText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if !option.isUnlocked {
                    Label("Complete the previous role play", systemImage: "lock.fill")
                        .font(.caption)
                        .foregroundStyle(palette.mutedText)
                } else if option.completionCount > 0 {
                    Label("\(option.completionCount) completed", systemImage: "checkmark.seal.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(palette.accent)
                } else {
                    HStack(spacing: 6) {
                        DoubloonIcon(size: 18)
                        Text("2 doubloons")
                            .font(.caption.weight(.semibold))
                    }
                }
            }
            Spacer(minLength: 0)
            if option.isUnlocked {
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(palette.mutedText)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(palette.surface.opacity(option.isUnlocked ? 1 : 0.55), in: RoundedRectangle(cornerRadius: 22))
    }
}
