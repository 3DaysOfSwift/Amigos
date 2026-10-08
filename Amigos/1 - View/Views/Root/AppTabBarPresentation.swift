import Observation
import SwiftUI

@MainActor
@Observable
final class AppTabBarPresentation {
    private var hiddenBy: Set<UUID> = []

    var isVisible: Bool { hiddenBy.isEmpty }

    func hide(for id: UUID) { hiddenBy.insert(id) }
    func show(for id: UUID) { hiddenBy.remove(id) }
}

private struct AppTabBarPresentationKey: EnvironmentKey {
    static let defaultValue: AppTabBarPresentation? = nil
}

extension EnvironmentValues {
    var appTabBarPresentation: AppTabBarPresentation? {
        get { self[AppTabBarPresentationKey.self] }
        set { self[AppTabBarPresentationKey.self] = newValue }
    }
}

private struct HidesAppTabBar: ViewModifier {
    @Environment(\.appTabBarPresentation) private var presentation
    @State private var id = UUID()

    func body(content: Content) -> some View {
        content
            .onAppear { presentation?.hide(for: id) }
            .onDisappear { presentation?.show(for: id) }
    }
}

extension View {
    func hidesAppTabBar() -> some View { modifier(HidesAppTabBar()) }
}
