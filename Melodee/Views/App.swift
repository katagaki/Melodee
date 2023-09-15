//
//  App.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2023/09/11.
//

import SwiftUI

@main
struct MelodeeApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    @StateObject var tabManager = TabManager()
    @StateObject var navigationManager = NavigationManager()
    @StateObject var fileManager = FilesystemManager()
    @StateObject var mediaPlayer = MediaPlayerManager()
    @StateObject var settings = SettingsManager()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(tabManager)
                .environmentObject(navigationManager)
                .environmentObject(fileManager)
                .environmentObject(mediaPlayer)
                .environmentObject(settings)
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions:
                        [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        application.beginReceivingRemoteControlEvents()
        return true
    }

}
