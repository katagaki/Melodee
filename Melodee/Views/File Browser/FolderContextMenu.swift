//
//  FolderContextMenu.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2023/09/12.
//

import SwiftUI

struct FolderContextMenu: View {

    @EnvironmentObject var navigationManager: NavigationManager
    @EnvironmentObject var fileManager: FilesystemManager
    @EnvironmentObject var mediaPlayer: MediaPlayerManager
    var directory: FSDirectory

    @Binding var isRenaming: Bool
    @Binding var directoryBeingRenamed: FSDirectory?

    var body: some View {
        Button {
            directoryBeingRenamed = directory
            isRenaming = true
        } label: {
            Label("Shared.Rename", systemImage: "pencil")
        }
    }
}
