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
    @State var selectedFolderName: String = ""

    @State var isCreatingPlaylist: Bool = false
    @State var newPlaylistName: String = ""

    @State var filesTabPath: [ViewPath] = []
    @State var forceRefreshFlag: Bool = false

    @Binding var externalFolderTabTitle: String

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
                            Text("Library.SelectAnotherFolder")
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
                        selectedFolderName = url.lastPathComponent
                        externalFolderTabTitle = url.lastPathComponent
                        filesTabPath.removeAll()
                        // Save bookmark for persistence
                        saveExternalFolderBookmark(url: url)
                        // Trigger refresh by toggling the flag
                        forceRefreshFlag.toggle()
                    } else {
                        url.stopAccessingSecurityScopedResource()
                    }
                })
                .ignoresSafeArea(edges: [.bottom])
            }
            .onAppear {
                // Restore external folder on first appearance
                restoreExternalFolderBookmark()
            }
            .hasFileBrowserNavigationDestinations()
        }
    }

    func saveExternalFolderBookmark(url: URL) {
        do {
            let bookmarkData = try url.bookmarkData(
                options: .minimalBookmark,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            UserDefaults.standard.set(bookmarkData, forKey: "ExternalFolderBookmark")
        } catch {
            debugPrint("Failed to create bookmark: \(error)")
        }
    }

    func restoreExternalFolderBookmark() {
        guard !hasSelectedExternalDirectory,
              let bookmarkData = UserDefaults.standard.data(forKey: "ExternalFolderBookmark") else {
            return
        }
        do {
            var isStale = false
            let url = try URL(
                resolvingBookmarkData: bookmarkData,
                options: .withoutUI,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
            if isStale {
                saveExternalFolderBookmark(url: url)
            }
            let isAccessSuccessful = url.startAccessingSecurityScopedResource()
            if isAccessSuccessful {
                fileManager.directory = url
                fileManager.storageLocation = .external
                hasSelectedExternalDirectory = true
                selectedFolderName = url.lastPathComponent
                externalFolderTabTitle = url.lastPathComponent
                forceRefreshFlag.toggle()
            }
        } catch {
            debugPrint("Failed to resolve bookmark: \(error)")
            UserDefaults.standard.removeObject(forKey: "ExternalFolderBookmark")
        }
    }
}
