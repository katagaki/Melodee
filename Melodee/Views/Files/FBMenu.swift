//
//  FBMenu.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2023/09/12.
//

import Komponents
import SwiftUI

struct FBMenu: View {

    @Binding var files: [any FilesystemObject]

    @State var validFiles: [FSFile] = []

    var body: some View {
        Menu {
            NavigationLink(value: ViewPath.tagEditorMultiple(files: validFiles)) {
                Label("Shared.EditTag.All", systemImage: "tag")
            }
        } label: {
            Label("Shared.More", systemImage: "ellipsis")
        }
        .task {
            validFiles.removeAll()
            for file in files {
                if let file = file as? FSFile, file.extension == "mp3" {
                    validFiles.append(file)
                }
            }
        }
    }
}
