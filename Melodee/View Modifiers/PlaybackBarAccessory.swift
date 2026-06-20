import SwiftUI
import TipKit

enum PlaybackBar {
    static let contentInset: CGFloat = 80.0
}

struct PlaybackBarAccessory: ViewModifier {

    @Environment(NowPlayingBarManager.self) var nowPlayingBarManager: NowPlayingBarManager

    @State var isPopupPresented: Bool = false
    @Namespace var namespace

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                if !nowPlayingBarManager.isKeyboardShowing {
                    Button {
                        isPopupPresented.toggle()
                    } label: {
                        NowPlayingBar()
                            .matchedTransitionSource(id: "NowPlayingBar", in: namespace)
                            .contentShape(.capsule)
                    }
                    .buttonStyle(.plain)
                    .glassEffect(.regular.interactive(), in: .capsule)
                    .popoverTip(NPQueueTip(), arrowEdge: .bottom)
                    .padding(.horizontal, 12.0)
                    .padding(.bottom, 8.0)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.default, value: nowPlayingBarManager.isKeyboardShowing)
            .sheet(isPresented: $isPopupPresented) {
                NowPlayingView()
                    .navigationTransition(
                        .zoom(sourceID: "NowPlayingBar", in: namespace)
                    )
            }
    }
}

struct PlaybackBarContentInset: ViewModifier {
    func body(content: Content) -> some View {
        content
            .safeAreaInset(edge: .bottom, spacing: 0.0) {
                Color.clear.frame(height: PlaybackBar.contentInset)
            }
    }
}

extension View {
    func playbackBarAccessory() -> some View {
        self.modifier(PlaybackBarAccessory())
    }

    func playbackBarContentInset() -> some View {
        self.modifier(PlaybackBarContentInset())
    }
}
