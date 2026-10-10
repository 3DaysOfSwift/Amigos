import SwiftUI

struct AmigoBioView: View {
    @Environment(ThemeManager.self) private var themeManager
    @State private var viewModel = AmigoBioViewModel()
    let amigo: Amigo

    private var palette: AppPalette { themeManager.currentTheme.palette }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                HStack {
                    Spacer()
                    AmigoPortrait(amigo: amigo, size: 164)
                    Spacer()
                }
                .padding(.top, 24)

                VStack(alignment: .leading, spacing: 8) {
                    Text(amigo.name)
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                    Text("YOUR AMIGO, BEYOND THE PHONE")
                        .font(.caption.weight(.bold))
                        .tracking(1.7)
                        .foregroundStyle(palette.accent)
                }

                Text(amigo.story)
                    .font(.body)
                    .lineSpacing(6)
                    .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Remembered for")
                        .font(.headline)
                    Text(amigo.rememberedFor)
                        .font(.body)
                        .foregroundStyle(palette.mutedText)
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(palette.surface, in: RoundedRectangle(cornerRadius: 22))

                VStack(alignment: .leading, spacing: 12) {
                    Text("A friendship that lives on")
                        .font(.title3.weight(.bold))
                    Text("Your amigos are ghosts, but their personalities and stories are still here. Each conversation gives you another way to know them—and to share a little of your own life. Tell \(amigo.name) about yourself. Keep the connection alive.")
                        .font(.body)
                        .foregroundStyle(palette.mutedText)
                        .lineSpacing(5)
                    Text(viewModel.messageCountDescription(for: amigo))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(palette.accent)
                }

                Text("These are fictional AI characters. Their stories are part of Amigos.")
                    .font(.footnote)
                    .foregroundStyle(palette.mutedText)
            }
            .padding(22)
        }
        .background(palette.background.ignoresSafeArea())
        .navigationTitle(amigo.name)
        .navigationBarTitleDisplayMode(.inline)
        .hidesAppTabBar()
    }
}
