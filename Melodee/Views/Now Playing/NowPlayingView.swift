//
//  NowPlayingView.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2023/09/11.
//

import MarqueeText
import MediaPlayer
import SwiftUI

struct NowPlayingView: View {

    @EnvironmentObject var mediaPlayer: MediaPlayerManager
    @State var currentDuration: TimeInterval = .zero
    @State var totalDuration: TimeInterval = .zero
    @State var isSeekbarSeeking: Bool = false
    @State var albumArt: Image = Image("Album.Generic")
    let updateTimer = Timer.publish(every: 1, on: .current, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .center, spacing: 16.0) {
                        albumArt
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200.0)
                            .clipShape(RoundedRectangle(cornerRadius: 16.0))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16.0)
                                    .stroke(.primary, lineWidth: 1/3)
                                    .opacity(0.3)
                            )
                            .shadow(color: .black.opacity(0.1), radius: 10.0)
                            .padding(.bottom)
                            .transition(.slide.animation(.default))
                        MarqueeText(text: mediaPlayer.currentQueueFile()?.name ??
                                    NSLocalizedString("Shared.NoFilePlaying", comment: ""),
                                    font: UIFont.preferredFont(forTextStyle: .body),
                                    leftFade: 16, rightFade: 16, startDelay: 1.5)
                        MusicProgressSlider(value: $currentDuration,
                                            inRange: .zero...totalDuration,
                                            activeFillColor: .accentColor,
                                            fillColor: .accentColor,
                                            emptyColor: .secondary.opacity(0.5),
                                            height: 24) { isEditing in
                                                isSeekbarSeeking = isEditing
                                                if !isSeekbarSeeking {
                                                    mediaPlayer.seekTo(currentDuration)
                                                }
                                            }
                        .frame(maxWidth: .infinity, minHeight: 32)
                        HStack(alignment: .center, spacing: 16.0) {
                            Spacer()
                            Group {
                                Button {
                                    mediaPlayer.backToStartOfTrack()
                                    currentDuration = .zero
                                    totalDuration = .zero
                                } label: {
                                    Image("Back")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 24.0, height: 24.0)
                                        .padding()
                                }
                                .foregroundStyle(.accent)
                                .disabled(!mediaPlayer.isPlaybackActive)
                                Group {
                                    if mediaPlayer.isPaused {
                                        Button {
                                            mediaPlayer.play()
                                            Task {
                                                await setAlbumArt()
                                            }
                                        } label: {
                                            Image("Play")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 32.0, height: 32.0)
                                                .padding()
                                        }
                                    } else {
                                        Button {
                                            mediaPlayer.pause()
                                        } label: {
                                            Image("Pause")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 32.0, height: 32.0)
                                                .padding()
                                        }
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                                Button {
                                    withAnimation(.default.speed(2)) {
                                        mediaPlayer.skipToNextTrack()
                                    }
                                } label: {
                                    Image("Next")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 24.0, height: 24.0)
                                        .padding()
                                }
                                .foregroundStyle(.accent)
                                .disabled(!mediaPlayer.canGoToNextTrack())
                            }
                            .clipShape(Circle())
                            Spacer()
                        }
                        .disabled(!mediaPlayer.canStartPlayback())
                        .buttonStyle(.plain)
                    }
                    .padding([.top, .bottom])
                } header: {
                    ListSectionHeader(text: "")
                }
                Section {
                    ForEach($mediaPlayer.queue, id: \.playbackQueueID) { $file in
                        HStack(alignment: .center, spacing: 8.0) {
                            if file == mediaPlayer.queue.first {
                                Image("Play")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 18.0, height: 18.0)
                                    .foregroundStyle(.accent)
                            }
                            Text(file.name)
                                .font(.body)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                        .moveDisabled(file == mediaPlayer.queue.first)
                        .deleteDisabled(file == mediaPlayer.queue.first)
                    }
                    .onMove { indexSet, offset in
                        mediaPlayer.queue.move(fromOffsets: indexSet, toOffset: offset)
                    }
                    .onDelete { indexSet in
                        mediaPlayer.queue.remove(atOffsets: indexSet)
                    }
                } header: {
                    HStack(alignment: .center, spacing: 8.0) {
                        ListSectionHeader(text: "Shared.Queue")
                            .font(.body)
                            .popoverTip(FileBrowserQueueTip(), arrowEdge: .bottom)
                        Spacer()
                        EditButton()
                            .bold()
                            .textCase(.none)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("ViewTitle.NowPlaying")
        }
        .task {
            await setAlbumArt()
        }
        .onChange(of: mediaPlayer.queue, { _, _ in
            Task {
                await setAlbumArt()
            }
        })
        .onReceive(updateTimer, perform: { _ in
            if !isSeekbarSeeking {
                if let audioPlayer = mediaPlayer.audioPlayer {
                    currentDuration = audioPlayer.currentTime
                    totalDuration = audioPlayer.duration
                } else {
                    currentDuration = .zero
                    totalDuration = .zero
                }
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
