import SwiftUI

extension View {
    func hidesAppTabBar() -> some View {
        toolbarVisibility(.hidden, for: .tabBar)
    }

    func tabBarScrollClearance() -> some View {
        padding(.bottom, 40)
    }
}
