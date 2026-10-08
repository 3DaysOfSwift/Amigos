import SwiftUI

struct ConversationsView: View {
    @Environment(ThemeManager.self) private var themeManager
    @State private var viewModel = ConversationsViewModel()
    @State private var selectedAmigo: Amigo?

    private var palette: AppPalette { themeManager.currentTheme.palette }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                brandHeader
                    .padding(.horizontal, 18)
                chatsHeading
                    .padding(.horizontal, 18)

                if viewModel.isSearching {
                    TextField("Search amigos", text: $viewModel.searchText)
                        .textInputAutocapitalization(.never)
                        .padding(14)
                        .background(palette.surface, in: RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal, 18)
                        .accessibilityLabel("Search amigos")
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

                VStack(alignment: .leading, spacing: 12) {
                    Text("SPECIAL PRACTICE")
                        .font(.caption.weight(.semibold))
                        .tracking(2)
                        .foregroundStyle(palette.mutedText)
                        .padding(.horizontal, 18)

                    NavigationLink {
                        RolePlayView()
                            .hidesAppTabBar()
                    } label: {
                        HStack(spacing: 18) {
                            Image("Amigos-Ayudante")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 74, height: 74)
                                .frame(width: 70, height: 70)
                                .clipShape(Circle())

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Role Play")
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text("Practise real moments in Spanish")
                                    .font(.subheadline)
                                    .foregroundStyle(palette.mutedText)
                            }
                            Spacer(minLength: 0)
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(palette.mutedText)
                        }
                        .padding(.vertical, 16)
                        .padding(.horizontal, 32)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                        .overlay {
                            Rectangle()
                                .strokeBorder(palette.mutedText.opacity(0.17), lineWidth: 1)
                                .allowsHitTesting(false)
                        }
                    }
                    .buttonStyle(ConversationRowButtonStyle(pressedBackground: palette.surface))
                }

                Text("Your amigos are AI characters. Conversations stay on this device.")
                    .font(.footnote)
                    .foregroundStyle(palette.mutedText)
                    .padding(.horizontal, 18)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 20)
            .padding(.bottom, 28)
        }
        .background(palette.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(item: $selectedAmigo) { amigo in
            ChatView(context: ChatContext(amigo: amigo, scenario: nil))
        }
    }

    private var brandHeader: some View {
        HStack(alignment: .center, spacing: 12) {
            AmigosWordmark(fontSize: 38)

            Spacer(minLength: 0)

            HStack(spacing: 7) {
                Image(systemName: "flame.fill")
                    .font(.title3)
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

    private var chatsHeading: some View {
        HStack(spacing: 12) {
            Text("Chats")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
            Spacer()
            Button(action: viewModel.toggleSearch) {
                Image(systemName: viewModel.isSearching ? "xmark" : "magnifyingglass")
                    .font(.title3.weight(.medium))
                    .frame(width: 48, height: 48)
                    .background(palette.surface, in: Circle())
            }
            .accessibilityLabel(viewModel.isSearching ? "Close search" : "Search chats")

            Menu {
                ForEach(viewModel.amigos) { amigo in
                    Button(amigo.name) { selectedAmigo = amigo }
                }
            } label: {
                Image(systemName: "square.and.pencil")
                    .font(.title3.weight(.medium))
                    .frame(width: 48, height: 48)
                    .background(palette.surface, in: Circle())
            }
            .accessibilityLabel("Choose an amigo to chat with")
        }
        .foregroundStyle(.primary)
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
