import SwiftUI

struct ConversationsView: View {
    @Environment(ThemeManager.self) private var themeManager
    @State private var viewModel = ConversationsViewModel()

    private var palette: AppPalette { themeManager.currentTheme.palette }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                HStack {
                    Label("Amigos · Chat", systemImage: "bubble.left.and.bubble.right.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(palette.accent)
                    Spacer()
                    HStack(spacing: 6) {
                        DoubloonIcon(size: 24)
                        Text("\(viewModel.doubloons)")
                    }
                        .font(.headline)
                        .accessibilityLabel("\(viewModel.doubloons) doubloons")
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("A conversation starts here.")
                        .font(.system(.largeTitle, design: .serif))
                    Text("Practise messaging a Spanish-speaking friend. Start with a real moment from your life, or step into a role play.")
                        .foregroundStyle(palette.mutedText)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Your amigos")
                        .font(.system(.title, design: .serif))
                    Text("Choose who you would like to talk to.")
                        .font(.subheadline)
                        .foregroundStyle(palette.mutedText)
                }

                LazyVStack(spacing: 12) {
                    ForEach(viewModel.amigos) { amigo in
                        NavigationLink {
                            ChatView(context: ChatContext(amigo: amigo, scenario: nil))
                        } label: {
                            HStack(spacing: 16) {
                                Text(String(amigo.name.prefix(1)))
                                    .font(.title2.weight(.semibold))
                                    .foregroundStyle(palette.accent)
                                    .frame(width: 48, height: 48)
                                    .background(palette.accent.opacity(0.12), in: Circle())
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(amigo.name)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    Text(amigo.identity)
                                        .font(.subheadline)
                                        .foregroundStyle(palette.mutedText)
                                        .lineLimit(2)
                                }
                                Spacer(minLength: 4)
                                Image(systemName: "chevron.right")
                                    .font(.caption.bold())
                                    .foregroundStyle(palette.mutedText)
                            }
                            .padding(18)
                            .background(palette.surface, in: RoundedRectangle(cornerRadius: 22))
                        }
                        .buttonStyle(.plain)
                    }
                }

                NavigationLink {
                    RolePlayView()
                } label: {
                    HStack(alignment: .top, spacing: 16) {
                        Image(systemName: "theatermasks.fill")
                            .font(.title2)
                            .foregroundStyle(palette.accent)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Role Play Real Life")
                                .font(.system(.title2, design: .serif))
                                .foregroundStyle(.primary)
                            Text("Order a coffee, meet a neighbour, or handle a little moment in Spanish.")
                                .font(.subheadline)
                                .foregroundStyle(palette.mutedText)
                        }
                        Spacer(minLength: 0)
                        Image(systemName: "arrow.up.right")
                            .foregroundStyle(palette.accent)
                    }
                    .padding(22)
                    .background(palette.surface, in: RoundedRectangle(cornerRadius: 24))
                }
                .buttonStyle(.plain)

                Text("Your partners are AI, not real people. Conversations run on your device with Apple Intelligence.")
                    .font(.footnote)
                    .foregroundStyle(palette.mutedText)
            }
            .padding(22)
        }
        .navigationTitle("Amigos")
        .background(palette.background.ignoresSafeArea())
    }
}
