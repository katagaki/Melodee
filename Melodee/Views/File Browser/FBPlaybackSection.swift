//
//  FBPlaybackSection.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2023/09/12.
//

import SwiftUI

struct FBPlaybackSection: View {

    @EnvironmentObject var mediaPlayer: MediaPlayerManager
    @Binding var currentDirectory: FSDirectory?
    @Binding var files: [any FilesystemObject]

    var body: some View {
        Section {
            HStack(alignment: .center, spacing: 8.0) {
                Group {
                    ActionButton(text: "Shared.PlayAll", icon: "Play", isPrimary: true) {
                        mediaPlayer.stop()
                        for file in files {
                            if let file = file as? FSFile, file.type == .audio {
                                mediaPlayer.queueLast(file: file)
                            }
                        }
                        mediaPlayer.play()
                    }
                    ActionButton(text: "Shared.Shuffle", icon: "Shuffle") {
                        mediaPlayer.stop()
                        var filesReordered: [FSFile] = []
                        for file in files {
                            if let file = file as? FSFile, file.type == .audio {
                                filesReordered.append(file)
                            }
                        }
                        filesReordered = filesReordered.shuffled()
                        for file in filesReordered {
                            mediaPlayer.queueLast(file: file)
                        }
                        mediaPlayer.play()
                    }
                }
                .frame(maxWidth: .infinity)
                .disabled(!folderContainsPlayableAudio())
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)
        } header: {
            Text(currentDirectory?.name ?? NSLocalizedString("ViewTitle.Files", comment: ""))
                .font(.largeTitle)
                .textCase(.none)
                .bold()
                .foregroundColor(.primary)
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 16, trailing: 0))
                .textSelection(.enabled)
        }
    }

    func folderContainsPlayableAudio() -> Bool {
        for file in files {
            if let file = file as? FSFile, file.type == .audio {
                return true
            }
        }
        return false
    }
}
