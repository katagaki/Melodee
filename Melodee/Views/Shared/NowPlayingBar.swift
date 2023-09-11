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
                        buttonImage(imageName: "Play")
                    }
                } else {
                    Button {
                        mediaPlayer.pause()
                    } label: {
                        buttonImage(imageName: "Pause")
                    }
                }
                if mediaPlayer.canGoToNextTrack() {
                    Button {
                        withAnimation(.default.speed(2)) {
                            mediaPlayer.skipToNextTrack()
                        }
                    } label: {
                        buttonImage(imageName: "Next")
                    }
                }
            }
            .disabled(!mediaPlayer.canStartPlayback())
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 72.0, maxHeight: 72.0)
        .background(.regularMaterial)
        .overlay(Rectangle().frame(width: nil,
                                    height: 1/3,
                                    alignment: .top).foregroundColor(.primary.opacity(0.3)),
                 alignment: .top)
    }

    @ViewBuilder
    func buttonImage(imageName: String) -> some View {
        Image(imageName)
            .resizable()
            .scaledToFit()
            .frame(width: 24.0, height: 24.0)
            .padding()
    }
}
