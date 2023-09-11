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
            Group {
                MarqueeText(text: mediaPlayer.currentlyPlayingFile() ??
                                NSLocalizedString("Shared.NoFilePlaying", comment: ""),
                            font: UIFont.preferredFont(forTextStyle: .body),
                            leftFade: 16, rightFade: 16, startDelay: 1.5)
            }
            .lineLimit(1)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity)
            Spacer()
            Divider()
            Group {
                if mediaPlayer.isPaused {
                    Button {
                        mediaPlayer.play()
                    } label: {
                        Image(systemName: "play.fill")
                            .resizable()
                            .frame(width: 24.0, height: 24.0)
                            .padding()
                    }
                } else {
                    Button {
                        mediaPlayer.pause()
                    } label: {
                        Image(systemName: "pause.fill")
                            .resizable()
                            .frame(width: 24.0, height: 24.0)
                            .padding()
                    }
                }
            }
            .disabled(!mediaPlayer.isPlaybackActive)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: 72.0)
        .background(.regularMaterial)
    }
}
