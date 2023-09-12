//
//  NowPlayingView.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2023/09/11.
//

import SwiftUI

struct NowPlayingView: View {

    @EnvironmentObject var mediaPlayer: MediaPlayerManager

    var body: some View {
        NavigationStack {
            List {
                NPControllerSection()
                NPQueueSection()
            }
            .listStyle(.insetGrouped)
            .navigationTitle("ViewTitle.NowPlaying")
        }
    }
}
