import SwiftUI

struct ConversationsView: View {
    @Environment(ThemeManager.self) private var themeManager
    @State private var viewModel = ConversationsViewModel()

    private var palette: AppPalette { themeManager.currentTheme.palette }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                chatsHeader
                    .padding(.horizontal, 18)

                if let error = viewModel.loadError {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(error)
                        Button("Try again", action: viewModel.retryLoading)
                            .disabled(viewModel.isRetrying)
                    }
                    .padding(.horizontal, 18)
                }

                if let error = viewModel.introductionError {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(error).font(.footnote)
                        Button("Retry welcome") { Task { await viewModel.introduceAmigos() } }
                    }
                    .padding(.horizontal, 18)
                }

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
                        .buttonStyle(ConversationRowButtonStyle(
                            background: viewModel.hasUnansweredMessage(from: amigo)
                                ? palette.streak.opacity(0.08) : .clear,
                            pressedBackground: palette.streak.opacity(0.20)))
                        .disabled(!viewModel.isLoaded)
                        .accessibilityLabel("Open chat with \(amigo.name)")
                        .accessibilityValue(viewModel.hasUnansweredMessage(from: amigo)
                            ? "Unanswered message" : "")

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

                Text("Your amigos are ghosts, but their personalities and stories are still here and live on through your conversation. Each conversation gives you another way to practice messaging in Spanish. Your amigos are AI characters. Conversations stay local on your device.")
                    .font(.footnote)
                    .foregroundStyle(palette.mutedText)
                    .padding(.horizontal, 18)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 8)
            .tabBarScrollClearance()
        }
        .background(palette.background.ignoresSafeArea())
        .task(id: viewModel.isLoaded) { await viewModel.introduceAmigos() }
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $viewModel.searchText, prompt: "Search amigos")
        .toolbar {
            ToolbarItem(placement: .principal) {
                AmigosScreenTitle(title: "Chats", fontSize: 19)
            }
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
                    .foregroundStyle(streakStatusColor)
                Text(viewModel.streakDescription)
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
                    .fixedSize()
                StreakBar(days: viewModel.currentWeek)
                Spacer(minLength: 0)
                Text(viewModel.streakStatusDescription)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(streakStatusColor)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .overlay {
                Capsule()
                    .stroke(streakStatusColor, lineWidth: 1.5)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(viewModel.streakDescription) streak, \(viewModel.streakStatusDescription)")
        }
    }

    private var streakStatusColor: Color {
        viewModel.hasCompletedDayStreak ? palette.online : .orange
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
            if viewModel.showsEarnedDoubloon(for: amigo) {
                DoubloonIcon(size: 26)
                    .accessibilityLabel("Doubloon earned today")
            } else {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(palette.mutedText)
                    .accessibilityHidden(true)
            }
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }
}

private struct ConversationRowButtonStyle: ButtonStyle {
    let background: Color
    let pressedBackground: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? pressedBackground : background)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
