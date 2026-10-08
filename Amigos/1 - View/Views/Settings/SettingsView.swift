import SwiftUI

struct SettingsView: View {
    @Environment(ThemeManager.self) private var themeManager
    @State private var viewModel = SettingsViewModel()

    private var palette: AppPalette { themeManager.currentTheme.palette }

    var body: some View {
        @Bindable var themeManager = themeManager

        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                VStack(alignment: .leading, spacing: 8) {
                    AmigosWordmark(fontSize: 36)
                    Text("Make it yours.")
                        .font(.system(.title2, design: .rounded, weight: .bold))
                    Text("A little Spanish, every day, with friends who always have something to say.")
                        .foregroundStyle(palette.mutedText)
                }

                VStack(alignment: .leading, spacing: 12) {
                    sectionHeading("APPEARANCE")
                    HStack {
                        Label("Colour theme", systemImage: "paintpalette.fill")
                        Spacer()
                        Picker("Colour theme", selection: $themeManager.currentTheme) {
                            ForEach(AppColourTheme.allCases) { theme in
                                Text(theme.name).tag(theme)
                            }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                    }
                    .padding(20)
                    .background(palette.surface, in: RoundedRectangle(cornerRadius: 20))

                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Label("Chat background", systemImage: "square.on.square")
                            Spacer()
                            Picker("Chat background", selection: $themeManager.currentWallpaper) {
                                ForEach(ChatWallpaper.allCases) { wallpaper in
                                    Text(wallpaper.name).tag(wallpaper)
                                }
                            }
                            .pickerStyle(.menu)
                            .labelsHidden()
                        }

                        ChatWallpaperView(wallpaper: themeManager.currentWallpaper, palette: palette)
                            .frame(height: 112)
                            .overlay(alignment: .leading) {
                                Text("¡Hola! ¿Qué tal?")
                                    .font(.subheadline)
                                    .padding(12)
                                    .background(palette.friendBubble, in: RoundedRectangle(cornerRadius: 16))
                                    .padding(14)
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 15))
                            .accessibilityLabel("Preview of \(themeManager.currentWallpaper.name) chat background")
                    }
                    .padding(20)
                    .background(palette.surface, in: RoundedRectangle(cornerRadius: 20))
                }

                VStack(alignment: .leading, spacing: 12) {
                    sectionHeading("YOUR PRACTICE")
                    NavigationLink {
                        ProfileView()
                    } label: {
                        HStack(spacing: 14) {
                            LearnerPortrait(size: 42)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(viewModel.displayName)
                                    .foregroundStyle(.primary)
                                Text("Your profile")
                                    .font(.footnote)
                                    .foregroundStyle(palette.mutedText)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(palette.mutedText)
                        }
                        .padding(20)
                        .background(palette.surface, in: RoundedRectangle(cornerRadius: 20))
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        WalletView()
                    } label: {
                        HStack(spacing: 14) {
                            DoubloonIcon(size: 31)
                            Text("Doubloons")
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(palette.mutedText)
                        }
                        .padding(20)
                        .background(palette.surface, in: RoundedRectangle(cornerRadius: 20))
                    }
                    .buttonStyle(.plain)
                }

                VStack(alignment: .leading, spacing: 12) {
                    sectionHeading("ABOUT")
                    VStack(alignment: .leading, spacing: 14) {
                        LabeledContent("App") {
                            AmigosWordmark(fontSize: 20)
                        }
                        Divider()
                        LabeledContent("AI", value: "On device")
                        Divider()
                        LabeledContent("Architecture", value: "CFA iOS Architecture")
                        Text("Built with Cooperative Feature Architecture.")
                            .font(.footnote)
                            .foregroundStyle(palette.mutedText)
                    }
                    .padding(20)
                    .background(palette.surface, in: RoundedRectangle(cornerRadius: 20))
                }

                Text("Practice typing Spanish with AI characters. Conversations remain on this device.\n\n\(viewModel.appVersion)")
                    .font(.footnote)
                    .foregroundStyle(palette.mutedText)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                    .padding(.top, 14)
            }
            .padding(22)
            .padding(.bottom, 100)
        }
        .navigationTitle("Settings")
        .background(palette.background.ignoresSafeArea())
    }

    private func sectionHeading(_ title: String) -> some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .tracking(2)
            .foregroundStyle(palette.mutedText)
            .padding(.leading, 4)
    }
}
