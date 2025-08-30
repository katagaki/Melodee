//
//  FileBrowser.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2025/08/30.
//

import SwiftUI

struct FileBrowserNavigationDestinations: ViewModifier {

    func body(content: Content) -> some View {
        content
            .navigationDestination(for: ViewPath.self, destination: { viewPath in
                switch viewPath {
                case .fileBrowser(let directory, let storageLocation):
                    FolderView(
                        currentDirectory: directory,
                        overrideStorageLocation: storageLocation
                    )
                case .imageViewer(let file):
                    ImageViewerView(file: file)
                case .textViewer(let file):
                    TextViewerView(file: file)
                case .pdfViewer(let file):
                    PDFViewerView(file: file)
                case .tagEditorSingle(let file):
                    TagEditorView(files: [file])
                case .tagEditorMultiple(let files):
                    TagEditorView(files: files)
                case .playlist(let playlist):
                    PlaylistView(playlist: playlist)
                default: Color.clear
                }
            })
    }
}

extension View {
    func hasFileBrowserNavigationDestinations() -> some View {
        self.modifier(FileBrowserNavigationDestinations())
    }
}
