//
//  AdaptiveTabBottomAccessory.swift
//  Melodee
//
//  Created by Copilot on 2025/10/25.
//

import SwiftUI
import LNPopupUI

struct AdaptiveTabBottomAccessory<BarContent: View, PopupContent: View>: ViewModifier {

    @Binding var isPopupPresented: Bool

    var barContent: () -> BarContent
    var popupContent: () -> PopupContent

    @Namespace private var namespace

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .tabBarMinimizeBehavior(.onScrollDown)
                .tabViewBottomAccessory {
                    barContent()
                        .matchedTransitionSource(id: "NowPlayingBar", in: namespace)
                }
                .sheet(isPresented: $isPopupPresented) {
                    popupContent()
                        // TODO: Navigation transition broken in iOS 26.1
                        .navigationTransition(
                            .zoom(sourceID: "NowPlayingBar", in: namespace)
                        )
                }
        } else {
            content
                .popup(
                    isBarPresented: .constant(true),
                    isPopupOpen: $isPopupPresented,
                    popupContent: popupContent
                )
                .popupBarCustomView(
                    wantsDefaultTapGesture: true,
                    wantsDefaultPanGesture: false,
                    wantsDefaultHighlightGesture: false
                ) {
                    barContent()
                }
        }
    }
}

extension View {
    func adaptiveTabBottomAccessory<BarContent: View, PopupContent: View>(
        isPopupPresented: Binding<Bool>,
        barContent: @escaping () -> BarContent,
        popupContent: @escaping () -> PopupContent
    ) -> some View {
        self.modifier(AdaptiveTabBottomAccessory(
            isPopupPresented: isPopupPresented,
            barContent: barContent,
            popupContent: popupContent
        ))
    }
}
