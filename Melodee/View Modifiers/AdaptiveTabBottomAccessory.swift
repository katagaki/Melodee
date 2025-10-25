//
//  AdaptiveTabBottomAccessory.swift
//  Melodee
//
//  Created by Copilot on 2025/10/25.
//

import SwiftUI
import LNPopupUI

extension View {
    @ViewBuilder
    func adaptiveTabBottomAccessory<BarContent: View, PopupContent: View>(
        isPopupPresented: Binding<Bool>,
        @ViewBuilder barContent: @escaping () -> BarContent,
        @ViewBuilder popupContent: @escaping () -> PopupContent
    ) -> some View {
        if #available(iOS 26.0, *) {
            self
                .tabViewBottomAccessory {
                    barContent()
                }
                .sheet(isPresented: isPopupPresented) {
                    popupContent()
                }
        } else {
            self
                .popup(
                    isBarPresented: .constant(true),
                    isPopupOpen: isPopupPresented,
                    popupContent: barContent
                )
                .popupBarCustomView(
                    wantsDefaultTapGesture: true,
                    wantsDefaultPanGesture: false,
                    wantsDefaultHighlightGesture: false
                ) {
                    popupContent()
                }
        }
    }
}
