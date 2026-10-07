import SwiftUI

struct SettingsView: View {
    @Environment(ThemeManager.self) private var themeManager
    @State private var viewModel = SettingsViewModel()

    var body: some View {
        @Bindable var themeManager = themeManager
        Form {
            Section("Appearance") {
                Picker("Colour theme", selection: $themeManager.currentTheme) {
                    ForEach(AppColourTheme.allCases) { theme in
                        Text(theme.name).tag(theme)
                    }
                }
                .pickerStyle(.menu)
            }
            Section("About") {
                LabeledContent("App", value: "Amigos")
                LabeledContent("AI", value: "Apple Intelligence, on device")
            }
            Section {
                Text(viewModel.appVersion).font(.footnote).foregroundStyle(.secondary)
            } footer: {
                Text("Practice typing Spanish with an AI chat partner. Conversations remain on this device.")
            }
        }
        .scrollContentBackground(.hidden)
        .background(themeManager.currentTheme.palette.background)
        .navigationTitle("Settings")
    }
}
