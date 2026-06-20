import SwiftUI

extension View {
    func adaptiveGlass() -> some View {
        self.glassEffect(.regular, in: .capsule)
    }
}
