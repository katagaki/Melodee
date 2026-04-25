//
//  AdaptiveTabBottomAccessory.swift
//  Melodee
//
//  Created by Copilot on 2025/10/25.
//

import SwiftUI
import TipKit

struct AdaptiveTabBottomAccessory: ViewModifier {

    @State var isPopupPresented: Bool = false
    @Namespace var namespace

    func body(content: Content) -> some View {
        content
            .tabBarMinimizeBehavior(.automatic)
            .tabViewBottomAccessory {
                Button {
                    isPopupPresented.toggle()
                } label: {
                    NowPlayingBar()
                        .matchedTransitionSource(id: "NowPlayingBar", in: namespace)
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .popoverTip(NPQueueTip(), arrowEdge: .bottom)
            }
            .sheet(isPresented: $isPopupPresented) {
                NowPlayingView()
                    .navigationTransition(
                        .zoom(sourceID: "NowPlayingBar", in: namespace)
                    )
            }
    }
}

extension View {
    func adaptiveTabBottomAccessory() -> some View {
        self.modifier(AdaptiveTabBottomAccessory())
    }
}
