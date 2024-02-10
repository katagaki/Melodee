//
//  NowPlayingView.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2023/09/11.
//

import SwiftUI

struct NowPlayingView: View {

    @Environment(\.dismiss) var dismiss
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
            .navigationTitle("ViewTitle.NowPlaying")
            .navigationBarTitleDisplayMode(settings.showNowPlayingTab ? .large : .inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if !settings.showNowPlayingTab {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.primary)
                                .symbolRenderingMode(.hierarchical)
                                .font(.title2)
                        }
                        .buttonStyle(.plain)
                    } else {
                        Color.clear
                    }
                }
            }
            .onAppear {
                isClearQueueButtonConfirming = false
            }
            .listRowBackground(Color.clear)
            .background {
                albumArt
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
