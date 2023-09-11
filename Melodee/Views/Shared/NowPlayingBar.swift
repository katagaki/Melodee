//
//  NowPlayingBar.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2023/09/11.
//

import MarqueeText
import SwiftUI

struct NowPlayingBar: View {

    @EnvironmentObject var mediaPlayer: MediaPlayerManager

    var body: some View {
        HStack {
            MarqueeText(text: mediaPlayer.currentlyPlayingFile() ??
                            NSLocalizedString("Shared.NoFilePlaying", comment: ""),
                        font: UIFont.preferredFont(forTextStyle: .body),
                        leftFade: 16, rightFade: 16, startDelay: 1.5)
            .frame(maxWidth: .infinity)
            Spacer()
            Divider()
            Group {
                if mediaPlayer.isPaused {
                    Button {
                        mediaPlayer.play()
                    } label: {
                        buttonImage(imageName: "play.fill")
                    }
                } else {
                    Button {
                        mediaPlayer.pause()
                    } label: {
                        buttonImage(imageName: "pause.fill")
                    }
                }
                if mediaPlayer.canGoToNextTrack() {
                    Button {
                        withAnimation(.default.speed(2)) {
                            mediaPlayer.skipToNextTrack()
                        }
                    } label: {
                        buttonImage(imageName: "forward.end.alt.fill")
                    }
                }
            }
            .disabled(!mediaPlayer.isPlaybackActive)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: 72.0)
        .background(.regularMaterial)
        .clipShape(UnevenRoundedRectangle(topLeadingRadius: 16.0,
                                          bottomLeadingRadius: 0.0,
                                          bottomTrailingRadius: 0.0,
                                          topTrailingRadius: 16.0,
                                          style: .continuous))
        .compositingGroup()
        .shadow(color: .black.opacity(0.1), radius: 6)
    }

    @ViewBuilder
    func buttonImage(imageName: String) -> some View {
        Image(systemName: imageName)
            .resizable()
            .scaledToFit()
            .frame(width: 24.0, height: 24.0)
            .padding()
    }
}
