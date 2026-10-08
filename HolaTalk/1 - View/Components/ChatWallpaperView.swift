import SwiftUI

struct ChatWallpaperView: View {
    let wallpaper: ChatWallpaper
    let palette: AppPalette

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                palette.background

                if !wallpaper.motifs.isEmpty {
                    ForEach(0..<60, id: \.self) { index in
                        let column = index % 5
                        let row = index / 5
                        motif(wallpaper.motifs[(index * 7 + row * 3) % wallpaper.motifs.count])
                            .frame(width: 34, height: 34)
                            .grayscale(1)
                            .opacity(0.14)
                            .rotationEffect(.degrees(Double((index % 5) * 8 - 16)))
                            .position(
                                x: (CGFloat(column) + 0.5 + (row.isMultiple(of: 2) ? 0 : 0.18)) * geometry.size.width / 5,
                                y: CGFloat(row) * 104 + 48
                            )
                    }
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipped()
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func motif(_ value: ChatWallpaperMotif) -> some View {
        switch value {
        case .emoji(let character):
            Text(character)
                .font(.system(size: 27))
        case .sombrero:
            SombreroShape()
                .fill(palette.mutedText)
                .frame(width: 32, height: 27)
        }
    }
}

private struct SombreroShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addEllipse(in: CGRect(x: rect.minX, y: rect.height * 0.70,
                                   width: rect.width, height: rect.height * 0.25))
        path.move(to: CGPoint(x: rect.width * 0.26, y: rect.height * 0.75))
        path.addQuadCurve(to: CGPoint(x: rect.width * 0.40, y: rect.height * 0.18),
                          control: CGPoint(x: rect.width * 0.32, y: rect.height * 0.64))
        path.addQuadCurve(to: CGPoint(x: rect.width * 0.60, y: rect.height * 0.18),
                          control: CGPoint(x: rect.width * 0.50, y: rect.height * 0.08))
        path.addQuadCurve(to: CGPoint(x: rect.width * 0.74, y: rect.height * 0.75),
                          control: CGPoint(x: rect.width * 0.68, y: rect.height * 0.64))
        path.closeSubpath()
        return path
    }
}
