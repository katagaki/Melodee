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
                    .popoverTip(NPQueueTip(), arrowEdge: .bottom)
                Spacer()
                EditButton()
                    .bold()
                    .textCase(.none)
            }
        }
    }
}
