import SwiftUI

struct ConversationsView: View {
    @Environment(ThemeManager.self) private var themeManager
    @State private var viewModel = ConversationsViewModel()
    @State private var selectedAmigo: Amigo?

    private var palette: AppPalette { themeManager.currentTheme.palette }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                chatsHeader
                    .padding(.horizontal, 18)

                LazyVStack(spacing: 0) {
                    if !viewModel.visibleAmigos.isEmpty {
                        Rectangle()
                            .fill(palette.mutedText.opacity(0.17))
                            .frame(height: 1)
                    }

                    ForEach(viewModel.visibleAmigos) { amigo in
                        NavigationLink {
                            ChatView(context: ChatContext(amigo: amigo, scenario: nil))
                        } label: {
                            amigoRow(amigo)
                        }
                        .buttonStyle(ConversationRowButtonStyle(pressedBackground: palette.surface))
                        .accessibilityLabel("Open chat with \(amigo.name)")

                        Rectangle()
                            .fill(palette.mutedText.opacity(0.17))
                            .frame(height: 1)
                    }
                }
                .frame(maxWidth: .infinity)

                if viewModel.visibleAmigos.isEmpty {
                    Text("No amigos found")
                        .foregroundStyle(palette.mutedText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 30)
                        .padding(.horizontal, 18)
                }

                Text("Your amigos are AI characters. Conversations stay on this device.")
                    .font(.footnote)
                    .foregroundStyle(palette.mutedText)
                    .padding(.horizontal, 18)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 8)
            .tabBarScrollClearance()
        }
        .background(palette.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $viewModel.searchText, prompt: "Search amigos")
        .toolbar {
            ToolbarItem(placement: .principal) {
                AmigosScreenTitle(title: "Chats", fontSize: 19)
            }
            ToolbarItemGroup(placement: .topBarTrailing) {
                Menu {
                    ForEach(viewModel.amigos) { amigo in
                        Button(amigo.name) { selectedAmigo = amigo }
                    }
                } label: {
                    Image(systemName: "square.and.pencil")
                }
                .accessibilityLabel("Choose an amigo to chat with")
            }
        }
        .navigationDestination(item: $selectedAmigo) { amigo in
            ChatView(context: ChatContext(amigo: amigo, scenario: nil))
        }
    }

    private var chatsHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 7) {
                DoubloonIcon(size: 28)
                Text("\(viewModel.doubloons)")
                    .font(.headline.weight(.semibold))
                    .monospacedDigit()
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(viewModel.doubloons) doubloons")

            HStack(spacing: 7) {
                Image(systemName: "flame.fill")
                    .font(.headline)
                    .foregroundStyle(palette.accent)
                Text(viewModel.streakDescription)
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
                    .fixedSize()
                StreakBar(days: viewModel.currentWeek)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(viewModel.streakDescription) streak")
        }
    }

    private func amigoRow(_ amigo: Amigo) -> some View {
        HStack(spacing: 18) {
            AmigoPortrait(amigo: amigo, size: 72)
            VStack(alignment: .leading, spacing: 7) {
                Text(amigo.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(viewModel.preview(for: amigo))
                    .font(.subheadline)
                    .foregroundStyle(palette.mutedText)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(palette.mutedText)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }
}

private struct ConversationRowButtonStyle: ButtonStyle {
    let pressedBackground: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? pressedBackground : .clear)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
