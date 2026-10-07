import SwiftUI

struct AppEntryView: View {
    @Environment(ThemeManager.self) private var themeManager
    @State private var viewModel = AppEntryViewModel()

    var body: some View {
        Group {
            if !viewModel.isLoaded {
                VStack(spacing: 16) {
                    if let error = viewModel.loadError {
                        Text(error).multilineTextAlignment(.center)
                        Button("Try again", action: viewModel.retryLoading)
                    } else {
                        ProgressView("Opening your conversations…")
                    }
                }
                .padding()
            } else {
                NavigationStack {
                    ChatView(context: viewModel.initialChatContext)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(themeManager.currentTheme.palette.background.ignoresSafeArea())
    }
}
