//
//  AdaptiveGlass.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2025/10/25.
//

import SwiftUI

struct AdaptiveGlass: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .glassEffect(.regular, in: .capsule)
        } else {
            content
        }
    }
}

extension View {
    func adaptiveGlass() -> some View {
        self.modifier(AdaptiveGlass())
    }
}
