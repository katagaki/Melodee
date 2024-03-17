//
//  FBTagSection.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2023/09/12.
//

import Komponents
import SwiftUI

struct FBTagSection: View {

    @EnvironmentObject var navigationManager: NavigationManager

    @Binding var files: [any FilesystemObject]

    var body: some View {
        Section {
            HStack(alignment: .center, spacing: 8.0) {
                Group {
                    ActionButton(text: "Shared.EditTag.All", icon: "Tag", isPrimary: false) {
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
            .listRowInsets(EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
            .listRowSeparator(.hidden, edges: .bottom)
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)
        }
    }
}
