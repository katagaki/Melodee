//
//  NPQueueSection.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2023/09/13.
//

import Komponents
import SwiftUI

struct NPQueueSection: View {

    @Environment(MediaPlayerManager.self) var mediaPlayer

    var body: some View {
        @Bindable var mediaPlayer = mediaPlayer
        Section {
            if $mediaPlayer.queue.isEmpty {
                Text(verbatim: "")
                    .listRowSeparator(.hidden)
            } else {
                ForEach($mediaPlayer.queue, id: \.playbackQueueID) { $file in
                    Button {
                        mediaPlayer.playImmediately(file, addToQueue: false)
                    } label: {
                        HStack(alignment: .center, spacing: 8.0) {
                            if file.playbackQueueID == mediaPlayer.currentlyPlayingID {
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
                            Spacer()
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .deleteDisabled(file.playbackQueueID == mediaPlayer.currentlyPlayingID)
                }
                .onMove { indexSet, offset in
                    mediaPlayer.queue.move(fromOffsets: indexSet, toOffset: offset)
                }
                .onDelete { indexSet in
                    mediaPlayer.queue.remove(atOffsets: indexSet)
                }
            }
        } header: {
            HStack(alignment: .center, spacing: 8.0) {
                ListSectionHeader(text: "Shared.Queue")
                Spacer()
                EditButton()
                    .bold()
                    .textCase(.none)
                    .disabled(mediaPlayer.queue.isEmpty)
            }
        }
    }
}
