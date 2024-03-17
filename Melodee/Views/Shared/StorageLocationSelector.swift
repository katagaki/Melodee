//
//  StorageLocationSelector.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2024/03/17.
//

import SwiftUI

struct StorageLocationSelector: View {

    @Environment(FilesystemManager.self) var fileManager

    @Binding var isSelectingExternalDirectory: Bool

    var body: some View {
        Menu {
            if FileManager.default.ubiquityIdentityToken != nil {
                Button {
                    fileManager.storageLocation = .cloud
                } label: {
                    Label("Shared.iCloudDrive", systemImage: "icloud")
                }
            }
            Button {
                fileManager.storageLocation = .local
            } label: {
                Label("Shared.OnMyDevice", systemImage: "iphone")
            }
            Button {
                isSelectingExternalDirectory = true
            } label: {
                Label("Shared.ExternalFolder", systemImage: "folder")
            }
            Divider()
            Button {
                let documentsUrl = FileManager.default.urls(for: .documentDirectory,
                                                            in: .userDomainMask).first!
                if let sharedUrl = URL(string: "shareddocuments://\(documentsUrl.path)") {
                    if UIApplication.shared.canOpenURL(sharedUrl) {
                        UIApplication.shared.open(sharedUrl, options: [:])
                    }
                }
            } label: {
                Label("Shared.OpenFilesApp", systemImage: "arrow.up.right.square")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
        }
        .sheet(isPresented: $isSelectingExternalDirectory) {
            DocumentPicker(allowedUTIs: [.folder], onDocumentPicked: { url in
                fileManager.directory = url
                fileManager.storageLocation = .external
                let isAccessSuccessful = url.startAccessingSecurityScopedResource()
                if !isAccessSuccessful {
                    url.stopAccessingSecurityScopedResource()
                }
            })
            .ignoresSafeArea(edges: [.bottom])
        }
    }
}
