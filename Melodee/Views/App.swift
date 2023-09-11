//
//  App.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2023/09/11.
//

import SwiftUI

@main
struct MelodeeApp: App {

    @StateObject var navigationManager = NavigationManager()
    @StateObject var fileManager = FilesystemManager()
    @StateObject var mediaPlayer = MediaPlayerManager()

    var body: some Scene {
        WindowGroup {
            FileBrowserView()
                .environmentObject(navigationManager)
                .environmentObject(fileManager)
                .environmentObject(mediaPlayer)
        }
    }
}
