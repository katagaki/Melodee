//
//  NowPlayingView.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2023/09/11.
//

import SwiftUI

struct NowPlayingView: View {

    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var mediaPlayer: MediaPlayerManager
    @EnvironmentObject var settings: SettingsManager
    @State var albumArt: Image = Image("Album.Generic")
    @State var previousQueueID: String = ""
    @State var isClearQueueButtonConfirming: Bool = false

    var body: some View {
        NavigationStack {
            List {
                Group {
                    NPControllerSection(albumArt: $albumArt)
                        .listRowSeparator(.hidden)
                        .padding(.top, 52.0)
                    NPQueueSection()
                    if !mediaPlayer.queue.isEmpty {
                        Section {
                            HStack(alignment: .center, spacing: 8.0) {
                                Group {
                                    ActionButton(text: isClearQueueButtonConfirming ?
                                                 "Shared.AreYouSure" : "NowPlaying.ClearQueue",
                                                 icon: "Clear") {
                                        withAnimation(.default.speed(2)) {
                                            if isClearQueueButtonConfirming {
                                                mediaPlayer.stop()
                                            }
                                            isClearQueueButtonConfirming.toggle()
                                        }
                                    }
                                                 .tint(.red)
                                }
                                .frame(maxWidth: .infinity)
                                .disabled(mediaPlayer.queue.isEmpty)
                            }
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .buttonStyle(.plain)
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
                .listRowBackground(Color.clear)
            }
            .listStyle(.plain)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .onAppear {
                isClearQueueButtonConfirming = false
            }
            .listRowBackground(Color.clear)
        }
        .presentationBackground {
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
