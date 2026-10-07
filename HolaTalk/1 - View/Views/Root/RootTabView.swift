import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            Tab("Chats", systemImage: "bubble.left.and.bubble.right.fill") {
                NavigationStack {
                    ConversationsView()
                }
            }

            Tab("Role Play", systemImage: "theatermasks.fill") {
                NavigationStack {
                    RolePlayView()
                }
            }

            Tab("Day Streak", systemImage: "flame.fill") {
                NavigationStack {
                    PracticeProgressView()
                }
            }

            Tab("Settings", systemImage: "gearshape.fill") {
                NavigationStack {
                    SettingsView()
                }
            }
        }
    }
}
