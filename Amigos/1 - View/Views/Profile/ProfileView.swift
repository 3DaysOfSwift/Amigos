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

                    Text("Your amigos can remember details you explicitly share in ordinary chats. Everything is optional and saved on this device. Edit or clear any field here. Role-play answers are never saved to your profile.")
                        .font(.footnote)
                        .foregroundStyle(palette.mutedText)
                }

                VStack(alignment: .leading, spacing: 18) {
                    ForEach(ProfileField.allCases) { field in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(field.title).font(.subheadline.weight(.semibold))
                            if field == .preferredAddress {
                                Picker(field.title, selection: detailBinding(field)) {
                                    Text("Not specified").tag("")
                                    Text("Amigo").tag("amigo")
                                    Text("Amiga").tag("amiga")
                                    Text("Neutral wording").tag("neutral")
                                }
                                .pickerStyle(.menu)
                            } else {
                                TextField("Optional", text: detailBinding(field))
                                    .keyboardType(field == .age ? .numberPad : .default)
                                    .padding(12)
                                    .background(palette.surface, in: RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }
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
                    Text(viewModel.isSaving ? "Saving…" : "Save profile")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!viewModel.canSave)

                if viewModel.didSave {
                    Label("Profile saved", systemImage: "checkmark.circle.fill")
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
        .hidesAppTabBar()
        .background(palette.background.ignoresSafeArea())
    }

    private func detailBinding(_ field: ProfileField) -> Binding<String> {
        Binding(get: { viewModel.draftDetails[field] ?? "" },
                set: { viewModel.draftDetails[field] = $0 })
    }
}
