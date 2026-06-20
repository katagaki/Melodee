import SwiftUI
import UIKit

struct TEAvailableTokenRow: View {

    var tokenName: String
    var tokenDescription: String

    @State private var didCopy: Bool = false

    var body: some View {
        HStack(alignment: .center, spacing: 12.0) {
            VStack(alignment: .leading, spacing: 2.0) {
                Text(verbatim: "%\(tokenName)%")
                    .textSelection(.enabled)
                    .font(.body.monospaced())
                    .bold()
                Text(NSLocalizedString(tokenDescription, comment: ""))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0.0)
            Button {
                UIPasteboard.general.string = "%\(tokenName)%"
                withAnimation(.default.speed(2)) {
                    didCopy = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    withAnimation(.default.speed(2)) {
                        didCopy = false
                    }
                }
            } label: {
                Image(systemName: didCopy ? "checkmark" : "doc.on.doc")
                    .foregroundStyle(didCopy ? .green : .accentColor)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(Text("Shared.Copy"))
        }
    }
}
