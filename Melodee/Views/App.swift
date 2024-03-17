//
//  App.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2023/09/11.
//

import SwiftUI

@main
struct MelodeeApp: App {

    @StateObject var tabManager: TabManager = TabManager()
    @StateObject var navigationManager: NavigationManager = NavigationManager()
    @State var filesystemManager: FilesystemManager = FilesystemManager()
    @State var playlistManager: PlaylistManager = PlaylistManager()
    @State var mediaPlayerManager: MediaPlayerManager = MediaPlayerManager()
    @State var nowPlayingBarManager: NowPlayingBarManager = NowPlayingBarManager()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .task {
                    debugPrint("Creating placeholder files")
                    filesystemManager.createPlaceholders()
                }
                .environmentObject(tabManager)
                .environmentObject(navigationManager)
                .environment(filesystemManager)
                .environment(playlistManager)
                .environment(mediaPlayerManager)
                .environment(nowPlayingBarManager)
        }
    }
}
