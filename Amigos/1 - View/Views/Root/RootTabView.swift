import SwiftUI

struct RootTabView: View {
    @Environment(ThemeManager.self) private var themeManager
    @State private var selectedTab: AppTab = .chats
    @Binding private var launchChatContext: ChatContext?

    private var palette: AppPalette { themeManager.currentTheme.palette }

    init(launchChatContext: Binding<ChatContext?>) {
        _launchChatContext = launchChatContext
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                ConversationsView()
                    .navigationDestination(item: $launchChatContext) { context in
                        ChatView(context: context)
                    }
            }
            .tabItem {
                Label(AppTab.chats.title, systemImage: AppTab.chats.symbol)
            }
            .tag(AppTab.chats)

            NavigationStack {
                RolePlayView()
            }
            .tabItem {
                Label(AppTab.rolePlay.title, systemImage: AppTab.rolePlay.symbol)
            }
            .tag(AppTab.rolePlay)

            NavigationStack {
                PracticeProgressView()
            }
            .tabItem {
                Label(AppTab.dayStreak.title, systemImage: AppTab.dayStreak.symbol)
            }
            .tag(AppTab.dayStreak)

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label(AppTab.settings.title, systemImage: AppTab.settings.symbol)
            }
            .tag(AppTab.settings)
        }
        .tint(palette.accent)
        .onChange(of: launchChatContext) { _, context in
            if context != nil { selectedTab = .chats }
        }
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
