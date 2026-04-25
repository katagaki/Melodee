//
//  AdaptiveGlass.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2025/10/25.
//

import SwiftUI

extension View {
    func adaptiveGlass() -> some View {
        self.glassEffect(.regular, in: .capsule)
    }
}
