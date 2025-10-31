//
//  FBContextMenu.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2023/09/12.
//

import SwiftUI

struct FBContextMenu: View {

    @Environment(FilesystemManager.self) var fileManager
    @Environment(MediaPlayerManager.self) var mediaPlayer

    @Binding var state: FBState
    var file: any FilesystemObject
    var extractZIPAction: () -> Void
    var convertAudioAction: ((AudioConversionFormat) -> Void)?

    var body: some View {
        if let file = file as? FSFile {
            // Context menu items for files
            // File type specific actions
            if file.type == .audio {
                Button {
                    mediaPlayer.playImmediately(file)
                } label: {
                    Label("Shared.Play", systemImage: "play")
                }
                Button {
                    withAnimation(.default.speed(2)) {
                        mediaPlayer.queueNext(file: file)
                    }
                } label: {
                    Label("Shared.Play.Next", systemImage: "text.line.first.and.arrowtriangle.forward")
                }
                Button {
                    withAnimation(.default.speed(2)) {
                        mediaPlayer.queueLast(file: file)
                    }
                } label: {
                    Label("Shared.Play.Last", systemImage: "text.line.last.and.arrowtriangle.forward")
                }
                Divider()
            } else if file.type == .image {
                if let image = UIImage(contentsOfFile: file.path) {
                    Button {
                        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                    } label: {
                        Label("Shared.SaveToPhotos", systemImage: "square.and.arrow.down")
                    }
                }
                Divider()
            } else if file.type == .zip {
                Button {
                    extractZIPAction()
                } label: {
                    Label("Shared.Extract", systemImage: "archivebox")
                }
                Divider()
            }
            // Audio conversion menu items
            if file.type == .audio, let convertAudioAction = convertAudioAction {
                Menu {
                    Button {
                        convertAudioAction(.mp3_320kbps)
                    } label: {
                        Label("Shared.ConvertTo.MP3", systemImage: "waveform")
                    }
                    Button {
                        convertAudioAction(.wav)
                    } label: {
                        Label("Shared.ConvertTo.WAV", systemImage: "waveform")
                    }
                    Button {
                        convertAudioAction(.m4a_128kbps)
                    } label: {
                        Label("Shared.ConvertTo.M4A", systemImage: "waveform")
                    }
                } label: {
                    Label("Shared.Convert", systemImage: "arrow.triangle.2.circlepath")
                }
                Divider()
            }
            // Tag Editor menu items
            if file.extension == "mp3" {
                NavigationLink(value: ViewPath.tagEditorSingle(file: file)) {
                    Label("Shared.EditTag.Single", systemImage: "tag")
                }
                Divider()
            }
            // Default item for all files
            Button {
                state.fileBeingRenamed = file
                state.isRenamingFile = true
            } label: {
                Label("Shared.Rename", systemImage: "pencil")
            }
        } else if let directory = file as? FSDirectory {
            // Context menu items for directories
            if isDirectoryEligibleForQueue(directory) {
                Button {
                    mediaPlayer.stop()
                    addToQueue(directory: directory)
                    mediaPlayer.play()
                } label: {
                    Label("Shared.Play.Folder", systemImage: "play")
                }
            }
            if isDirectoryEligibleForQueueRecursively(directory) {
                Button {
                    mediaPlayer.stop()
                    addToQueue(directory: directory, recursively: true)
                    mediaPlayer.play()
                } label: {
                    Label("Shared.Play.Folder.Recursive", systemImage: "play")
                }
            }
            if isDirectoryEligibleForQueue(directory) || isDirectoryEligibleForQueueRecursively(directory) {
                Divider()
            }
            Button {
                state.directoryBeingRenamed = directory
                state.isRenamingDirectory = true
            } label: {
                Label("Shared.Rename", systemImage: "pencil")
            }
        }
        Button(role: .destructive) {
            state.fileOrDirectoryBeingDeleted = file
            state.isDeletingFileOrDirectory = true
        } label: {
            Label("Shared.Delete", systemImage: "trash")
        }
    }

    func isDirectoryEligibleForQueue(_ directory: FSDirectory) -> Bool {
        if let url = URL(string: directory.path) {
            let files = fileManager.files(in: url).filter({ $0 is FSFile })
            return files.contains(where: { file in
                if let file = file as? FSFile {
                    return file.type == .audio
                }
                return false
            })
        }
        return false
    }

    func isDirectoryEligibleForQueueRecursively(_ directory: FSDirectory) -> Bool {
        if let url = URL(string: directory.path) {
            let files = fileManager.files(in: url).filter({ $0 is FSDirectory })
            for file in files {
                if let directory = file as? FSDirectory {
                    let filesInDirectory = fileManager.files(in: url)
                    if filesInDirectory.contains(where: { file in
                        if let file = file as? FSFile {
                            return file.type == .audio
                        }
                        return false
                    }) {
                        return true
                    } else {
                        return isDirectoryEligibleForQueueRecursively(directory)
                    }
                }
            }
        }
        return false
    }

    func addToQueue(directory: FSDirectory, recursively isRecursiveAdd: Bool = false) {
        if let url = URL(string: directory.path) {
            let contents = fileManager.files(in: url).sorted { lhs, rhs in
                lhs.name < rhs.name
            }
            for content in contents {
                if let file = content as? FSFile, file.type == .audio {
                    mediaPlayer.queueLast(file: file)
                }
            }
            if isRecursiveAdd {
                for content in contents {
                    if let directory = content as? FSDirectory {
                        addToQueue(directory: directory, recursively: isRecursiveAdd)
                    }
                }
            }
        }
    }
}
