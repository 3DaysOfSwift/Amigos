import SwiftUI

struct AmigosWordmark: View {
    let fontSize: CGFloat

    var body: some View {
        HStack(alignment: .top, spacing: 3) {
            Text("Amigos")
                .font(.system(size: fontSize, weight: .heavy, design: .rounded))
                .tracking(-fontSize * 0.05)
                .foregroundStyle(.primary)
            AmigosBrandDashMark(size: fontSize * 0.52)
                .padding(.top, fontSize * 0.08)
        }
        .fixedSize()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Amigos")
    }
}
