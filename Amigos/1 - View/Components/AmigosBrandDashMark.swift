import SwiftUI

struct AmigosBrandDashMark: View {
    let size: CGFloat

    var body: some View {
        HStack(alignment: .top, spacing: size * 0.06) {
            Capsule()
                .frame(width: size * 0.15, height: size * 0.36)
                .rotationEffect(.degrees(18))
                .offset(y: -size * 0.07)
            Capsule()
                .frame(width: size * 0.15, height: size * 0.33)
                .rotationEffect(.degrees(48))
                .offset(y: size * 0.13)
        }
        .foregroundStyle(Color(red: 1, green: 0.72, blue: 0.30))
        .accessibilityHidden(true)
    }
}

struct AmigosScreenTitle: View {
    let title: String
    let fontSize: CGFloat

    var body: some View {
        HStack(alignment: .top, spacing: fontSize * 0.08) {
            Text(title)
                .font(.system(size: fontSize, weight: .heavy, design: .rounded))
                .tracking(-fontSize * 0.04)
            AmigosBrandDashMark(size: fontSize * 0.58)
                .padding(.top, fontSize * 0.04)
        }
        .fixedSize()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
    }
}
