//
//  AdaptiveTabBottomAccessory.swift
//  Melodee
//
//  Created by Copilot on 2025/10/25.
//

import SwiftUI
import LNPopupUI
import TipKit

struct AdaptiveTabBottomAccessory: ViewModifier {

    @State var isPopupPresented: Bool = false
    @Namespace var namespace

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .tabBarMinimizeBehavior(.onScrollDown)
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
        } else {
            content
                .popup(
                    isBarPresented: .constant(true),
                    isPopupOpen: $isPopupPresented,
                    popupContent: { NowPlayingView() }
                )
                .popupBarCustomView(
                    wantsDefaultTapGesture: true,
                    wantsDefaultPanGesture: false,
                    wantsDefaultHighlightGesture: false
                ) {
                    NowPlayingBar()
                        .popoverTip(NPQueueTip(), arrowEdge: .bottom)
                }
        }
    }
}

extension View {
    func adaptiveTabBottomAccessory() -> some View {
        self.modifier(AdaptiveTabBottomAccessory())
    }
}
