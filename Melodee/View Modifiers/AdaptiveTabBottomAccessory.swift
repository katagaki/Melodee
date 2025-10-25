//
//  AdaptiveTabBottomAccessory.swift
//  Melodee
//
//  Created by Copilot on 2025/10/25.
//

import SwiftUI
import LNPopupUI

extension View {
    /// Adds a bottom accessory view to a TabView that persists across all tabs.
    /// On iOS 19+, uses native `.tabViewBottomAccessory`.
    /// On iOS 18, uses LNPopupUI as a fallback.
    @ViewBuilder
    func adaptiveTabBottomAccessory<BarContent: View, PopupContent: View>(
        isPopupPresented: Binding<Bool>,
        @ViewBuilder barContent: @escaping () -> BarContent,
        @ViewBuilder popupContent: @escaping () -> PopupContent
    ) -> some View {
        if #available(iOS 19.0, *) {
            self.tabViewBottomAccessory {
                barContent()
            }
            .sheet(isPresented: isPopupPresented) {
                popupContent()
            }
        } else {
            self.popup(isBarPresented: .constant(true), isPopupOpen: isPopupPresented) {
                popupContent()
            } popup: {
                barContent()
            }
            .popupBarCustomView(wantsDefaultTapGesture: true, wantsDefaultPanGesture: false, wantsDefaultHighlightGesture: false)
        }
    }
}
