//
//  NowPlayingView.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2023/09/11.
//

import Komponents
import SwiftUI

struct NowPlayingView: View {

    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @Environment(MediaPlayerManager.self) var mediaPlayer

    @State var albumArt: Image = Image("Album.Generic")
    @State var previousQueueID: String = ""
    @State var isClearQueueButtonConfirming: Bool = false

    var body: some View {
        List {
            Group {
                NPControllerSection(albumArt: $albumArt)
                    .listRowSeparator(.hidden)
                    .padding(.top, 28.0)
                NPQueueSection()
                    .alignmentGuide(.listRowSeparatorTrailing) { dimensions in
                        return dimensions.width
                    }
                if !mediaPlayer.queue.isEmpty {
                    Section {
                        Button {
                            withAnimation(.default.speed(2)) {
                                if isClearQueueButtonConfirming {
                                    mediaPlayer.stop()
                                }
                                isClearQueueButtonConfirming.toggle()
                            }
                        } label: {
                            Label(
                                (
                                    isClearQueueButtonConfirming ?
                                    String(localized: "Shared.AreYouSure") :
                                    String(localized: "NowPlaying.ClearQueue")
                                ),
                                systemImage: "eraser.line.dashed"
                            )
                        }
                        .foregroundStyle(.red)
                        .disabled(mediaPlayer.queue.isEmpty)
                        .listRowSeparator(.hidden)
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .listRowInsets(.init(top: 0.0, leading: 32.0, bottom: 0.0, trailing: 32.0))
            .listRowBackground(Color.clear)
        }
        .listStyle(.plain)
        .listSectionSpacing(.compact)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            isClearQueueButtonConfirming = false
        }
        .background {
            ZStack {
                switch colorScheme {
                case .light: Color.white
                case .dark: Color.black
                @unknown default: Color.black
                }
                albumArt
                    .aspectRatio(contentMode: .fill)
                    .blur(radius: 64.0)
                    .opacity(0.3)
            }
        }
        .task {
            if previousQueueID != mediaPlayer.currentlyPlayingID {
                await setAlbumArt()
                previousQueueID = mediaPlayer.currentlyPlayingID
            }
        }
        .onChange(of: mediaPlayer.currentlyPlayingID, { _, _ in
            Task {
                await setAlbumArt()
                previousQueueID = mediaPlayer.currentlyPlayingID
            }
        })
    }

    func setAlbumArt() async {
        let albumArtUIImage = await mediaPlayer.albumArt()
        withAnimation(.default.speed(2)) {
            albumArt = Image(uiImage: albumArtUIImage)
        }
    }
}
