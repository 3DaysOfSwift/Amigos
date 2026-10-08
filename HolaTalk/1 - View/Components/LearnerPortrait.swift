import SwiftUI

struct LearnerPortrait: View {
    let size: CGFloat

    var body: some View {
        Image("LearnerPortrait")
            .resizable()
            .scaledToFill()
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: size * 0.24))
            .accessibilityHidden(true)
    }
}
