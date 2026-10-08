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
                        Button("Try again") {
                            Task { await viewModel.retryLoading() }
                        }
                    } else {
                        ProgressView("Opening your conversations…")
                    }
                }
                .padding()
            } else {
                RootTabView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(themeManager.currentTheme.palette.background.ignoresSafeArea())
    }
}
