import SwiftUI

struct WalletBalance: View {
    let doubloons: Int

    var body: some View {
        HStack(spacing: 12) {
            DoubloonIcon(size: 40)
            VStack(alignment: .leading) {
                Text("Your balance").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                Text("\(doubloons) doubloons").font(.title2.bold()).monospacedDigit()
            }
            Spacer()
        }
    }
}
