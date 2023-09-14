//
//  NPQueueSection.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2023/09/13.
//

import SwiftUI

struct NPQueueSection: View {

    @EnvironmentObject var mediaPlayer: MediaPlayerManager

    var body: some View {
        Section {
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
        } header: {
            HStack(alignment: .center, spacing: 8.0) {
                ListSectionHeader(text: "Shared.Queue")
                    .font(.body)
                    .popoverTip(NPQueueTip(), arrowEdge: .bottom)
                Spacer()
                EditButton()
                    .bold()
                    .textCase(.none)
            }
        }
    }
}
