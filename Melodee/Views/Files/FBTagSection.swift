//
//  FBTagSection.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2023/09/12.
//

import SwiftUI

struct FBTagSection: View {

    @Environment(NavigationManager.self) var navigationManager

    @Binding var files: [any FilesystemObject]

    var body: some View {
        Section {
            HStack(alignment: .center, spacing: 8.0) {
                Group {
                    ActionButton(text: "Shared.EditTag.All", icon: "Tag") {
                        var validFiles: [FSFile] = []
                        for file in files {
                            if let file = file as? FSFile, file.extension == "mp3" {
                                validFiles.append(file)
                            }
                        }
                        navigationManager.push(ViewPath.tagEditorMultiple(files: validFiles),
                                               for: .fileManager)
                    }
                }
                .frame(maxWidth: .infinity)
                .disabled(!files.contains(where: { $0 is FSFile }))
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)
        }
    }
}
