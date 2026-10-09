import SwiftUI

struct RolePlayView: View {
    @Environment(ThemeManager.self) private var themeManager
    @State private var viewModel = RolePlayViewModel()

    private var palette: AppPalette { themeManager.currentTheme.palette }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 10) {
                    DoubloonIcon(size: 26)
                    Text("\(viewModel.doubloons) doubloons available")
                        .fontWeight(.semibold)
                }
                .font(.subheadline)
                .padding(.vertical, 14)
                .padding(.horizontal, 18)
                .background(palette.surface, in: RoundedRectangle(cornerRadius: 20))

                LazyVStack(spacing: 12) {
                    ForEach(viewModel.options) { option in
                        if option.isUnlocked {
                            NavigationLink { ChatView(context: option.context) } label: {
                                RolePlayCell(option: option)
                            }
                            .buttonStyle(RolePlayRowButtonStyle(highlight: palette.streak))
                        } else {
                            RolePlayCell(option: option)
                        }
                    }
                }
            }
            .padding(.horizontal, 18)
            .tabBarScrollClearance()
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                AmigosScreenTitle(title: "Role Play", fontSize: 19)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .background(palette.background.ignoresSafeArea())
    }
}

private struct RolePlayRowButtonStyle: ButtonStyle {
    let highlight: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .overlay {
                RoundedRectangle(cornerRadius: 22)
                    .fill(highlight.opacity(configuration.isPressed ? 0.26 : 0))
                    .allowsHitTesting(false)
            }
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
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
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(palette.surface.opacity(option.isUnlocked ? 1 : 0.55), in: RoundedRectangle(cornerRadius: 22))
        .grayscale(option.isUnlocked ? 0 : 1)
        .opacity(option.isUnlocked ? 1 : 0.52)
    }
}
