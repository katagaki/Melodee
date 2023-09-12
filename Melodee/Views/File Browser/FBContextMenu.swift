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
            switch file.type {
            case .audio:
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
            case .image:
                Divider()
            case .zip:
                Button {
                    extractZIPAction()
                } label: {
                    Label("Shared.Extract", systemImage: "archivebox")
                }
                Divider()
            }
            Button {
                state.fileBeingRenamed = file
                state.isRenamingFile = true
            } label: {
                Label("Shared.Rename", systemImage: "pencil")
            }
            if file.extension == "mp3" {
                Divider()
                Button {
                    navigationManager.push(ViewPath.tagEditorSingle(file: file), for: .fileManager)
                } label: {
                    Label("Shared.EditTag.Single", systemImage: "tag")
                }
            }
        } else if let directory = file as? FSDirectory {
            Button {
                state.directoryBeingRenamed = directory
                state.isRenamingDirectory = true
            } label: {
                Label("Shared.Rename", systemImage: "pencil")
            }
        }
    }
}
