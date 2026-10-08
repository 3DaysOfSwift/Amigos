import SwiftUI

struct DoubloonIcon: View {
    var size: CGFloat = 28

    private let highlight = Color(red: 1, green: 0.92, blue: 0.60)
    private let gold = Color(red: 0.95, green: 0.66, blue: 0.17)
    private let shadow = Color(red: 0.40, green: 0.23, blue: 0.035)

    var body: some View {
        ZStack {
            Circle()
                .fill(LinearGradient(colors: [highlight, gold, shadow],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
            Circle().strokeBorder(shadow, lineWidth: size * 0.035)
            Circle().inset(by: size * 0.09)
                .strokeBorder(highlight.opacity(0.9), lineWidth: size * 0.025)
            Circle().inset(by: size * 0.14)
                .strokeBorder(shadow.opacity(0.5), lineWidth: size * 0.018)
            Image(systemName: "bubble.left.fill")
                .font(.system(size: size * 0.38, weight: .semibold))
                .foregroundStyle(shadow)
                .shadow(color: highlight, radius: 0, x: 0, y: size * 0.015)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}
