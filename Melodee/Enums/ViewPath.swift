import Foundation

enum ViewPath: Hashable {
    case fileBrowser(directory: FSDirectory?, storageLocation: StorageLocation?)
    case imageViewer(file: FSFile)
    case textViewer(file: FSFile)
    case pdfViewer(file: FSFile)
    case playlistViewer(file: FSFile, scopeRootURL: URL)
    case moreAttributions
}
