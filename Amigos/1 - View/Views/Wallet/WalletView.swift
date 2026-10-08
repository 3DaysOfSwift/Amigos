import SwiftUI

struct WalletView: View {
    @Environment(ThemeManager.self) private var themeManager
    @State private var viewModel = WalletViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 26) {
            Text("Your doubloons").font(.system(.largeTitle, design: .rounded, weight: .bold))
            WalletBalance(doubloons: viewModel.doubloons)
                .padding(20).background(themeManager.currentTheme.palette.surface, in: RoundedRectangle(cornerRadius: 22))
            VStack(alignment: .leading, spacing: 12) {
                Label("How they work", systemImage: "info.circle.fill")
                    .font(.headline)
                    .foregroundStyle(themeManager.currentTheme.palette.accent)
                Text("Chatting with Amigos is free. Slide to start a Role Play for two doubloons. You are charged after its first successful reply, and can return to it for ten minutes.")
                Text("Amigos begins with ten welcome doubloons. With each Amigo, earn one after 10 successful exchanges in a day, then another for every 40 more. Role Plays do not earn doubloons.")
                    .foregroundStyle(.secondary)
            }
            .padding(20).background(themeManager.currentTheme.palette.surface, in: RoundedRectangle(cornerRadius: 22))
            Spacer()
        }
        .padding(22)
        .navigationTitle("Doubloons")
        .hidesAppTabBar()
        .background(themeManager.currentTheme.palette.background)
    }
}
