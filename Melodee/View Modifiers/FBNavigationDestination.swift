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
                case .playlistViewer(let file, let scopeRootURL):
                    PlaylistDetailView(
                        file: file,
                        fileManager: FilesystemManager(),
                        scopeRootURL: scopeRootURL
                    )
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
