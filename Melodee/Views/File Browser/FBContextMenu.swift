//
//  FBContextMenu.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2023/09/12.
//

import SwiftUI

struct FBContextMenu: View {

    @EnvironmentObject var navigationManager: NavigationManager
    @EnvironmentObject var fileManager: FilesystemManager
    @EnvironmentObject var mediaPlayer: MediaPlayerManager
    @Binding var state: FBState
    var file: any FilesystemObject
    var extractZIPAction: () -> Void

    var body: some View {
        if let file = file as? FSFile {
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
            if file.extension == "mp3" {
                Button {
                    navigationManager.push(ViewPath.tagEditorSingle(file: file), for: .fileManager)
                } label: {
                    Label("Shared.EditTag.Single", systemImage: "tag")
                }
                Divider()
            }
            Button {
                state.fileBeingRenamed = file
                state.isRenamingFile = true
            } label: {
                Label("Shared.Rename", systemImage: "pencil")
            }
        } else if let directory = file as? FSDirectory {
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
}
