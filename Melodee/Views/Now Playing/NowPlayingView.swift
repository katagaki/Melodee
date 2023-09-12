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
                if !mediaPlayer.queue.isEmpty {
                    Section {
                        HStack(alignment: .center, spacing: 8.0) {
                            Group {
                                ActionButton(text: "NowPlaying.ClearQueue", icon: "Clear") {
                                    mediaPlayer.stop()
                                }
                                .tint(.red)
                            }
                            .frame(maxWidth: .infinity)
                            .disabled(mediaPlayer.queue.isEmpty)
                        }
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        .buttonStyle(.plain)
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("ViewTitle.NowPlaying")
        }
    }
}
