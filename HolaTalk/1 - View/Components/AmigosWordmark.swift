import SwiftUI

struct AmigosWordmark: View {
    let fontSize: CGFloat

    var body: some View {
        HStack(alignment: .top, spacing: 3) {
            Text("Amigos")
                .font(.system(size: fontSize, weight: .heavy, design: .rounded))
                .tracking(-fontSize * 0.05)
                .foregroundStyle(.primary)

            HStack(alignment: .top, spacing: 2) {
                Capsule()
                    .frame(width: fontSize * 0.13, height: fontSize * 0.32)
                    .rotationEffect(.degrees(18))
                    .offset(y: -fontSize * 0.06)
                Capsule()
                    .frame(width: fontSize * 0.13, height: fontSize * 0.29)
                    .rotationEffect(.degrees(48))
                    .offset(y: fontSize * 0.12)
            }
            .foregroundStyle(Color(red: 1, green: 0.72, blue: 0.30))
            .padding(.top, fontSize * 0.08)
        }
        .fixedSize()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Amigos")
    }
}
