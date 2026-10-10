import SwiftUI

struct RolePlayAdmissionView: View {
    @Environment(ThemeManager.self) private var themeManager
    @Environment(\.layoutDirection) private var layoutDirection
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @GestureState private var translation: CGFloat = 0
    @State private var model = RolePlayAdmissionViewModel()
    @ScaledMetric(relativeTo: .headline) private var handleSize: CGFloat = 58

    let cost: Int
    let canConfirm: Bool
    let phase: ChatViewModel.AdmissionPhase
    let coinAnimation: Namespace.ID
    let confirm: () -> Bool

    var body: some View {
        let palette = themeManager.currentTheme.palette
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 14) {
                DoubloonIcon(size: 46)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Cost: \(cost) doubloons")
                        .font(.title3.weight(.bold))
                    Text("Put your Spanish into practice")
                        .font(.subheadline)
                        .foregroundStyle(palette.mutedText)
                }
            }
            .opacity(phase == .accepted || phase == .ready ? 1 : 0)
            GeometryReader { geometry in
                let travel = max(0, geometry.size.width - handleSize - 12)
                let rightToLeft = layoutDirection == .rightToLeft
                let distance = min(travel, max(0, rightToLeft ? -translation : translation))

                ZStack(alignment: rightToLeft ? .trailing : .leading) {
                    Capsule().fill(palette.surface)
                    Capsule().strokeBorder(palette.accent.opacity(0.55), lineWidth: 1)
                    Label("Slide to start", systemImage: "chevron.forward")
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity)
                        .opacity(model.confirmed ? 0 : 1 - Double(distance / max(1, travel)))
                    DoubloonIcon(size: handleSize)
                        .matchedGeometryEffect(id: "admission-coin", in: coinAnimation,
                                               properties: reduceMotion ? [] : .frame)
                        .padding(6)
                        .offset(x: (rightToLeft ? -1 : 1) * (model.confirmed ? travel : distance))
                        .gesture(DragGesture(minimumDistance: 8)
                            .updating($translation) { value, state, _ in state = value.translation.width }
                            .onEnded { value in
                                model.finish(translation: value.translation.width, travel: travel,
                                             rightToLeft: rightToLeft, confirm: confirm)
                            })
                }
                .animation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.8), value: translation)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Slide to start Role Play for \(cost) doubloons")
                .accessibilityHint("Charged after the first successful reply")
                .accessibilityAddTraits(.isButton)
                .accessibilityAction { if canConfirm { model.activate(confirm: confirm) } }
                .opacity(phase == .accepted || phase == .ready ? 1 : 0)
            }
            .frame(height: handleSize + 12)

            Text("Your doubloons are charged only after your first successful reply. Slide to begin a real-life conversation with your amigo.")
                .font(.footnote)
                .foregroundStyle(palette.mutedText)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 8)
                .opacity(phase == .accepted || phase == .ready ? 1 : 0)
        }
        .opacity(canConfirm || phase != .ready ? 1 : 0.5)
        .allowsHitTesting(canConfirm && phase == .ready)
    }

}
