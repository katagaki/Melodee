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
    @State var albumArt: Image = Image("Album.Generic")

    var body: some View {
        HStack(alignment: .center, spacing: 16.0) {
            albumArt
                .resizable()
                .scaledToFit()
                .frame(height: 40.0)
                .clipShape(RoundedRectangle(cornerRadius: 8.0))
                .overlay(
                    RoundedRectangle(cornerRadius: 8.0)
                        .stroke(.primary, lineWidth: 1/3)
                        .opacity(0.3)
                )
                .shadow(color: .black.opacity(0.1), radius: 10.0)
                .transition(.slide.animation(.default))
            MarqueeText(text: mediaPlayer.currentlyPlayingFilename() ??
                            NSLocalizedString("Shared.NoFilePlaying", comment: ""),
                        font: UIFont.preferredFont(forTextStyle: .body),
                        leftFade: 16, rightFade: 16, startDelay: 1.5)
            .frame(maxWidth: .infinity)
            HStack(alignment: .center, spacing: 8.0) {
                Divider()
                if mediaPlayer.isPaused {
                    Button {
                        withAnimation(.default.speed(2)) {
                            mediaPlayer.play()
                        }
                    } label: {
                        buttonImage(imageName: "Play")
                    }
                } else {
                    Button {
                        withAnimation(.default.speed(2)) {
                            mediaPlayer.pause()
                        }
                    } label: {
                        buttonImage(imageName: "Pause")
                    }
                }
                if mediaPlayer.isPlaybackActive && mediaPlayer.canGoToNextTrack() {
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
        .padding(.all, 8.0)
        .frame(maxWidth: .infinity, minHeight: 56.0, maxHeight: 56.0)
        .background(.regularMaterial)
        .overlay(Rectangle().frame(width: nil,
                                    height: 1/3,
                                    alignment: .top).foregroundColor(.primary.opacity(0.3)),
                 alignment: .top)
        .task {
            await setAlbumArt()
        }
        .onChange(of: mediaPlayer.currentlyPlayingID, { _, _ in
            Task {
                await setAlbumArt()
            }
        })
    }

    func setAlbumArt() async {
        let albumArtUIImage = await mediaPlayer.albumArt()
        withAnimation(.default.speed(2)) {
            albumArt = Image(uiImage: albumArtUIImage)
        }
    }

    @ViewBuilder
    func buttonImage(imageName: String) -> some View {
        Image(imageName)
            .resizable()
            .scaledToFit()
            .frame(width: 20.0, height: 20.0)
            .padding()
    }
}
