import SwiftUI

struct WalletView: View {
    @Environment(ThemeManager.self) private var themeManager
    @State private var viewModel = WalletViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 26) {
            Text("Your doubloons").font(.system(.largeTitle, design: .serif))
            WalletBalance(doubloons: viewModel.doubloons)
                .padding(20).background(themeManager.currentTheme.palette.surface, in: RoundedRectangle(cornerRadius: 22))
            VStack(alignment: .leading, spacing: 12) {
                Label("How they work", systemImage: "info.circle.fill").font(.headline).foregroundStyle(.mint)
                Text("One doubloon starts a friend conversation. Two doubloons start a Role Play. A paid conversation remains available for ten minutes, even if the app is closed.")
                Text("Amigos begins with ten welcome doubloons. Complete one real conversation each day to earn one more.")
                    .foregroundStyle(.secondary)
            }
            .padding(20).background(themeManager.currentTheme.palette.surface, in: RoundedRectangle(cornerRadius: 22))
            Spacer()
        }
        .padding(22)
        .navigationTitle("Doubloons")
        .background(themeManager.currentTheme.palette.background)
    }
}
