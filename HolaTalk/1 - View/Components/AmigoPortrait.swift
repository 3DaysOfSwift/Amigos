import SwiftUI

struct AmigoPortrait: View {
    let amigo: Amigo
    let size: CGFloat

    var body: some View {
        Image("Amigo-\(amigo.id)")
            .resizable()
            .scaledToFill()
            .frame(width: size, height: size)
            .clipShape(Circle())
            .accessibilityHidden(true)
    }
}
