//
//  CircularProgressView.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2026/04/08.
//

import SwiftUI

struct CircularProgressView: View {

    var progress: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(.secondary.opacity(0.3), lineWidth: 2.5)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(.accent, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.3), value: progress)
        }
    }
}
