import SwiftUI

struct RootTabView: View {
    @Environment(ThemeManager.self) private var themeManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selectedTab: AppTab = .chats
    @State private var tabBarPresentation = AppTabBarPresentation()

    private var palette: AppPalette { themeManager.currentTheme.palette }

    var body: some View {
        ZStack {
            tabContent(.chats) { ConversationsView() }
            tabContent(.rolePlay) { RolePlayView() }
            tabContent(.dayStreak) { PracticeProgressView() }
            tabContent(.settings) { SettingsView() }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if tabBarPresentation.isVisible {
                tabBar
                    .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(reduceMotion ? .easeOut(duration: 0.15) : .spring(response: 0.42, dampingFraction: 0.86),
                   value: tabBarPresentation.isVisible)
        .environment(\.appTabBarPresentation, tabBarPresentation)
    }

    private func tabContent<Content: View>(_ tab: AppTab, @ViewBuilder content: () -> Content) -> some View {
        NavigationStack { content() }
            .opacity(selectedTab == tab ? 1 : 0)
            .allowsHitTesting(selectedTab == tab)
            .accessibilityHidden(selectedTab != tab)
    }

    private var tabBar: some View {
        HStack(spacing: 2) {
            ForEach(AppTab.allCases) { tab in
                Button {
                    withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.symbol)
                            .font(.system(size: 23, weight: .semibold))
                            .frame(height: 27)
                        Text(tab.title)
                            .font(.caption2.weight(.semibold))
                            .lineLimit(1)
                    }
                    .foregroundStyle(selectedTab == tab ? palette.accent : palette.mutedText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .background(selectedTab == tab ? palette.surface : .clear, in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selectedTab == tab ? .isSelected : [])
            }
        }
        .padding(5)
        .background(palette.background.opacity(0.96), in: Capsule())
        .overlay(Capsule().strokeBorder(palette.mutedText.opacity(0.22), lineWidth: 1))
        .padding(.horizontal, 16)
        .padding(.bottom, 5)
        .background(palette.background.opacity(0.97))
    }
}

private enum AppTab: String, CaseIterable, Identifiable {
    case chats, rolePlay, dayStreak, settings

    var id: String { rawValue }
    var title: String {
        switch self {
        case .chats: "Chats"
        case .rolePlay: "Role Play"
        case .dayStreak: "Day Streak"
        case .settings: "Settings"
        }
    }
    var symbol: String {
        switch self {
        case .chats: "bubble.left.and.bubble.right.fill"
        case .rolePlay: "theatermasks.fill"
        case .dayStreak: "flame.fill"
        case .settings: "gearshape.fill"
        }
    }
}
