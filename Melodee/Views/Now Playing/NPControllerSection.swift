//
//  NPControllerSection.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2023/09/13.
//

import MarqueeText
import SwiftUI

struct NPControllerSection: View {

    @EnvironmentObject var mediaPlayer: MediaPlayerManager
    @State var albumArt: Image = Image("Album.Generic")
    @State var currentDuration: TimeInterval = .zero
    @State var totalDuration: TimeInterval = .zero
    @State var isSeekbarSeeking: Bool = false
    @State var previousQueueID: String = ""

    let updateTimer = Timer.publish(every: 0.5, on: .current, in: .common).autoconnect()

    var body: some View {
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
                MarqueeText(text: mediaPlayer.currentlyPlayingFile()?.name ??
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
                            withAnimation(.default.speed(2)) {
                                mediaPlayer.backToPreviousTrack()
                                currentDuration = .zero
                                totalDuration = .zero
                            }
                        } label: {
                            Image("Back")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24.0, height: 24.0)
                                .padding()
                        }
                        .foregroundStyle(.accent)
                        .disabled(!(mediaPlayer.isPlaybackActive && mediaPlayer.canGoToPreviousTrack()))
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
                        .disabled(!(mediaPlayer.isPlaybackActive && mediaPlayer.canGoToNextTrack()))
                    }
                    .clipShape(Circle())
                    Spacer()
                }
                .disabled(!mediaPlayer.canStartPlayback())
                .buttonStyle(.plain)
            }
            .padding([.top, .bottom])
            .background {
                albumArt
                    .blur(radius: 64.0)
                    .opacity(0.3)
            }
        } header: {
            ListSectionHeader(text: "")
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
