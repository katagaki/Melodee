//
//  FileBrowserNavigationStack.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2024/03/16.
//

import SwiftUI

struct FileBrowserNavigationStack: View {

    @EnvironmentObject var navigationManager: NavigationManager

    var body: some View {
        NavigationStack(path: $navigationManager.filesTabPath) {
            FileBrowserView()
                .navigationDestination(for: ViewPath.self, destination: { viewPath in
                    switch viewPath {
                    case .fileBrowser(let directory): FileBrowserView(currentDirectory: directory)
                    case .imageViewer(let file): ImageViewerView(file: file)
                    case .textViewer(let file): TextViewerView(file: file)
                    case .pdfViewer(let file): PDFViewerView(file: file)
                    case .tagEditorSingle(let file): TagEditorView(files: [file])
                    case .tagEditorMultiple(let files): TagEditorView(files: files)
                    default: Color.clear
                    }
                })
        }
    }
}
