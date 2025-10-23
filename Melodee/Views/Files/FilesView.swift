//
//  FilesView.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2024/03/16.
//

import Komponents
import SwiftUI

struct FilesView: View {

    @State var fileManager: FilesystemManager = FilesystemManager()

    @State var isSelectingExternalDirectory: Bool = false
    @State var hasSelectedExternalDirectory: Bool = false

    @State var isCreatingPlaylist: Bool = false
    @State var newPlaylistName: String = ""

    @State var filesTabPath: [ViewPath] = []
    @State var forceRefreshFlag: Bool = false

    @Namespace var namespace

    var body: some View {
        NavigationStack(path: $filesTabPath) {
            Group {
                if hasSelectedExternalDirectory {
                    // Show the external folder browser
                    FolderView(
                        currentDirectory: nil,
                        overrideStorageLocation: .external,
                        fileManager: fileManager
                    )
                    .id(forceRefreshFlag)
                } else {
                    // Show ContentUnavailableView when no folder is selected
                    ContentUnavailableView {
                        Label("Library.NoFolder.Title", systemImage: "folder.badge.questionmark")
                    } description: {
                        Text("Library.NoFolder.Description")
                    } actions: {
                        Button {
                            isSelectingExternalDirectory = true
                        } label: {
                            Text("Library.SelectFolder")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            .navigationTitle("ViewTitle.Files")
            .scrollContentBackground(.hidden)
            .background(
                .linearGradient(
                    colors: [.backgroundGradientTop, .backgroundGradientBottom],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .toolbar {
                if hasSelectedExternalDirectory {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            isSelectingExternalDirectory = true
                        } label: {
                            Label("Library.SelectAnotherFolder", systemImage: "folder.badge.plus")
                        }
                    }
                }
            }
            .sheet(isPresented: $isSelectingExternalDirectory) {
                DocumentPicker(allowedUTIs: [.folder], onDocumentPicked: { url in
                    fileManager.directory = url
                    fileManager.storageLocation = .external
                    let isAccessSuccessful = url.startAccessingSecurityScopedResource()
                    if isAccessSuccessful {
                        hasSelectedExternalDirectory = true
                        filesTabPath.removeAll()
                        // Trigger refresh by toggling the flag
                        forceRefreshFlag.toggle()
                    } else {
                        url.stopAccessingSecurityScopedResource()
                    }
                })
                .ignoresSafeArea(edges: [.bottom])
            }
            .hasFileBrowserNavigationDestinations()
        }
    }
}
