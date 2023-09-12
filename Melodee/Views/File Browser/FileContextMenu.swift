//
//  FileContextMenu.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2023/09/12.
//

import SwiftUI

struct FileContextMenu: View {

    @EnvironmentObject var navigationManager: NavigationManager
    @EnvironmentObject var fileManager: FilesystemManager
    @EnvironmentObject var mediaPlayer: MediaPlayerManager
    var file: FSFile

    @Binding var isRenaming: Bool
    @Binding var fileBeingRenamed: FSFile?

    var body: some View {
        if file.type == .audio {
            Button {
                mediaPlayer.playImmediately(file)
            } label: {
                Label("Shared.Play", systemImage: "play.fill")
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
        }
        Button {
            fileBeingRenamed = file
            isRenaming = true
        } label: {
            Label("Shared.Rename", systemImage: "pencil")
        }
        if file.extension == "mp3" {
            Divider()
            Button {
                navigationManager.push(ViewPath.tagEditorSingle(file: file), for: .fileManager)
            } label: {
                Label("Shared.EditTag.Single", systemImage: "tag.fill")
            }
        }
    }
}
