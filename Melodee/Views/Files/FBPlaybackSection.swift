//
//  FBPlaybackSection.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2023/09/12.
//

import Komponents
import SwiftUI

struct FBPlaybackSection: View {

    @Environment(MediaPlayerManager.self) var mediaPlayer

    @Binding var currentDirectory: FSDirectory?
    @Binding var files: [any FilesystemObject]

    var body: some View {
        Section {
            Text(currentDirectory?.name ?? NSLocalizedString("ViewTitle.Files", comment: ""))
                .font(.largeTitle)
                .textCase(.none)
                .bold()
                .foregroundColor(.primary)
                .listRowSeparator(.hidden) //, edges: .top)
                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 8, trailing: 16))
                .textSelection(.enabled)
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
                    ActionButton(text: "Shared.Shuffle", icon: "Shuffle", isPrimary: false) {
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
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 22, trailing: 16))
            .alignmentGuide(.listRowSeparatorLeading) { _ in
                return 0.0
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)
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
