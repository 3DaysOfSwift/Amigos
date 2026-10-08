import SwiftUI

struct AmigoPortrait: View {
    let amigo: Amigo
    let size: CGFloat

    var body: some View {
        Image("Amigos-\(amigo.id.capitalized)")
            .resizable()
            .scaledToFill()
            .frame(width: size * 1.06, height: size * 1.06)
            .frame(width: size, height: size)
            .clipShape(Circle())
            .accessibilityHidden(true)
    }
}
