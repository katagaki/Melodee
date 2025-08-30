//
//  FilesView.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2024/03/16.
//

import Komponents
import SwiftUI

struct FilesView: View {

    @Environment(FilesystemManager.self) var fileManager

    @State var isSelectingExternalDirectory: Bool = false

    @State var isCreatingPlaylist: Bool = false
    @State var newPlaylistName: String = ""

    @State var filesTabPath: [ViewPath] = []
    @State var forceRefreshFlag: Bool = false

    @Namespace var namespace

    var body: some View {
        NavigationStack(path: $filesTabPath) {
            List {
                Section {
                    Button {
                        isSelectingExternalDirectory = true
                    } label: {
                        Text("Shared.ExternalFolder")
                    }
                }
                Section {
                    Button {
                        let documentsUrl = FileManager.default.urls(for: .documentDirectory,
                                                                    in: .userDomainMask).first!
                        if let sharedUrl = URL(string: "shareddocuments://\(documentsUrl.path)") {
                            if UIApplication.shared.canOpenURL(sharedUrl) {
                                UIApplication.shared.open(sharedUrl, options: [:])
                            }
                        }
                    } label: {
                        ListRow(image: "ListIcon.Files", title: "Shared.OpenFilesApp")
                    }
                }
            }
            .navigationTitle("ViewTitle.Library")
            .scrollContentBackground(.hidden)
            .background(
                .linearGradient(
                    colors: [.backgroundGradientTop, .backgroundGradientBottom],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .refreshable {
                forceRefreshFlag.toggle()
            }
            .sheet(isPresented: $isSelectingExternalDirectory) {
                DocumentPicker(allowedUTIs: [.folder], onDocumentPicked: { url in
                    fileManager.directory = url
                    fileManager.storageLocation = .external
                    let isAccessSuccessful = url.startAccessingSecurityScopedResource()
                    if isAccessSuccessful {
                        filesTabPath.append(
                            ViewPath.fileBrowser(
                                directory: nil,
                                storageLocation: .external
                            )
                        )
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
