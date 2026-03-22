//
//  App.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2023/09/11.
//

import SwiftUI

@main
struct MelodeeApp: App {

    @State var fileManager: FilesystemManager = FilesystemManager()
    @State var mediaPlayerManager: MediaPlayerManager = MediaPlayerManager()
    @State var nowPlayingBarManager: NowPlayingBarManager = NowPlayingBarManager()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .task {
                    debugPrint("Creating placeholder files")
                    fileManager.createPlaceholders()
                }
                .environment(fileManager)
                .environment(mediaPlayerManager)
                .environment(nowPlayingBarManager)
        }
    }
}
