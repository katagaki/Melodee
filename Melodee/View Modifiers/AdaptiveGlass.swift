//
//  AdaptiveGlass.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2025/10/25.
//

import SwiftUI

extension View {
    @ViewBuilder
    func adaptiveGlass() -> some View {
        if #available(iOS 26.0, *) {
            self
                .glassEffect(.regular, in: .capsule)
        } else {
            self
        }
    }
}
