import SwiftUI

extension View {
    func hidesAppTabBar() -> some View {
        toolbar(.hidden, for: .tabBar)
    }

    func tabBarScrollClearance() -> some View {
        padding(.bottom, 40)
    }
}
