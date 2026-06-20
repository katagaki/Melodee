import SwiftUI

@main
struct MelodeeApp: App {

    @State var fileManager: FilesystemManager = FilesystemManager()
    @State var mediaPlayerManager: MediaPlayerManager = MediaPlayerManager()
    @State var nowPlayingBarManager: NowPlayingBarManager = NowPlayingBarManager()
    @State var fileDownloadManager: FileDownloadManager = FileDownloadManager()
    @State var externalFoldersManager: ExternalFoldersManager = ExternalFoldersManager()

    var body: some Scene {
        WindowGroup {
            MainView()
                .task {
                    debugPrint("Creating placeholder files")
                    fileManager.createPlaceholders()
                    mediaPlayerManager.downloadManager = fileDownloadManager
                }
                .environment(fileManager)
                .environment(mediaPlayerManager)
                .environment(nowPlayingBarManager)
                .environment(fileDownloadManager)
                .environment(externalFoldersManager)
        }
    }
}
