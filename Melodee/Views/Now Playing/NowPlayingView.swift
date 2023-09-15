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
    @State var isClearQueueButtonConfirming: Bool = false

    var body: some View {
        NavigationStack {
            List {
                NPControllerSection()
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
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        .buttonStyle(.plain)
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .listStyle(.insetGrouped)
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
        }
    }
}
