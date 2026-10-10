import SwiftUI

struct AppEntryView: View {
    @Environment(ThemeManager.self) private var themeManager
    @Environment(\.scenePhase) private var scenePhase
    @State private var viewModel = AppEntryViewModel()
    @State private var showsStreakMoment = true
    @State private var launchChatContext: ChatContext?

    var body: some View {
        ZStack {
            RootTabView(launchChatContext: $launchChatContext)
            if viewModel.isLoaded,
               let streak = viewModel.launchStreak,
               let invitation = viewModel.dailyInvitation,
               showsStreakMoment {
                DayStreakLaunchView(streak: streak, invitation: invitation) {
                    launchChatContext = ChatContext(amigo: invitation.amigo, scenario: nil, startsWithGreeting: true)
                    withAnimation(.easeOut(duration: 0.28)) {
                        showsStreakMoment = false
                    }
                }
                .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(themeManager.currentTheme.palette.background.ignoresSafeArea())
        .onAppear {
            openNotificationChat()
        }
        .onChange(of: viewModel.notificationAmigoID) { _, _ in
            openNotificationChat()
        }
        .onChange(of: viewModel.isLoaded) { _, _ in
            openNotificationChat()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                if viewModel.shouldPresentStreakMomentAfterReturn() {
                    withAnimation(.easeIn(duration: 0.25)) {
                        showsStreakMoment = true
                    }
                }
            } else {
                viewModel.recordAppBecameInactive()
            }
        }
    }

    private func openNotificationChat() {
        if let context = viewModel.takeNotificationChat() {
            showsStreakMoment = false
            launchChatContext = context
        }
    }
}

private struct DayStreakLaunchView: View {
    let streak: Int
    let invitation: DailyAmigoInvitation
    let startChat: () -> Void

    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 12) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 54, weight: .bold))
                    .foregroundStyle(.orange)
                Text("\(streak)")
                    .font(.system(size: 96, weight: .bold, design: .rounded))
                    .monospacedDigit()
                Text("day streak")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)

                Button(action: startChat) {
                    HStack(spacing: 14) {
                        AmigoPortrait(amigo: invitation.amigo, size: 64)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("¿Hablas con \(invitation.amigo.name) hoy?")
                                .font(.headline)
                            Text("Gana un doubloon y mantén tu racha.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.headline.weight(.bold))
                    }
                    .padding(16)
                }
                .buttonStyle(StreakInvitationButtonStyle())
                .accessibilityLabel("Talk with \(invitation.amigo.name) to earn a doubloon and keep your streak")
            }
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                AmigoPortrait(amigo: invitation.amigo, size: proxy.size.height)
                    .opacity(0.20)
                    .offset(x: 50, y: 100)
                    .allowsHitTesting(false)
            }
        }
        .background(.ultraThinMaterial)
    }
}

private struct StreakInvitationButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background {
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(.black.opacity(configuration.isPressed ? 0.28 : 0))
                    }
            }
            .contentShape(RoundedRectangle(cornerRadius: 24))
            .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
