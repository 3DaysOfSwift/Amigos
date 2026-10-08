import SwiftUI

struct ProfileView: View {
    @Environment(ThemeManager.self) private var themeManager
    @State private var viewModel = ProfileViewModel()

    private var palette: AppPalette { themeManager.currentTheme.palette }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                VStack(spacing: 16) {
                    LearnerPortrait(size: 142)
                    Text("The living friend")
                        .font(.system(.title, design: .rounded, weight: .bold))
                    Text("The Amigos are ghosts. You’re the person keeping their stories alive by talking with them.")
                        .foregroundStyle(palette.mutedText)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)

                VStack(alignment: .leading, spacing: 14) {
                    Text("YOUR NAME")
                        .font(.caption.weight(.semibold))
                        .tracking(2)
                        .foregroundStyle(palette.mutedText)

                    TextField("Your name", text: $viewModel.draftName)
                        .textContentType(.nickname)
                        .textInputAutocapitalization(.words)
                        .padding(16)
                        .background(palette.surface, in: RoundedRectangle(cornerRadius: 18))
                        .accessibilityLabel("Your display name")

                    Text("Only your name is saved on this device. No account is needed.")
                        .font(.footnote)
                        .foregroundStyle(palette.mutedText)
                }

                if let loadError = viewModel.loadError {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(loadError)
                            .foregroundStyle(.red)
                        Button("Try opening profile again") {
                            Task { await viewModel.retryLoading() }
                        }
                    }
                }

                Button {
                    Task { await viewModel.save() }
                } label: {
                    Text(viewModel.isSaving ? "Saving…" : "Save name")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!viewModel.canSave)

                if viewModel.didSave {
                    Label("Name saved", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(palette.online)
                }
                if let error = viewModel.error {
                    Text(error)
                        .foregroundStyle(.red)
                }
            }
            .padding(22)
        }
        .navigationTitle("Your profile")
        .toolbar(.hidden, for: .tabBar)
        .background(palette.background.ignoresSafeArea())
    }
}
