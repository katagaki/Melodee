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

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(tabManager)
                .environment(NavigationManager())
                .environment(FilesystemManager())
                .environment(PlaylistManager())
                .environment(MediaPlayerManager())
        }
    }
}
