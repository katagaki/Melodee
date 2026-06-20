//
//  MainTabView.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2023/09/11.
//

import SwiftUI
import TipKit

struct MainTabView: View {

    @Environment(NowPlayingBarManager.self) var nowPlayingBarManager: NowPlayingBarManager

    @State var localFilesTabPath: [ViewPath] = []
    @State var cloudFilesTabPath: [ViewPath] = []
    @AppStorage("SelectedTab") var selectedTab: Int = 0
    @Namespace private var nowPlayingNamespace

    @Namespace var namespace

    var body: some View {
        @Bindable var nowPlayingBarManager = nowPlayingBarManager

        TabView(selection: $selectedTab) {
            Tab("Tab.Local", systemImage: "iphone", value: 0) {
                NavigationStack(path: $localFilesTabPath) {
                    FolderView(
                        currentDirectory: nil,
                        overrideStorageLocation: .local
                    )
                    .hasFileBrowserNavigationDestinations()
                }
            }
            if FileManager.default.ubiquityIdentityToken != nil {
                Tab("Tab.Cloud", systemImage: "cloud.fill", value: 1) {
                    NavigationStack(path: $cloudFilesTabPath) {
                        FolderView(
                            currentDirectory: nil,
                            overrideStorageLocation: .cloud
                        )
                        .hasFileBrowserNavigationDestinations()
                    }
                }
            }
            Tab("Tab.ExternalFolders", systemImage: "folder.fill", value: 2) {
                FilesView()
            }
        }
        .task {
            // The More tab (value 3) was removed; reset stale selections to the first tab.
            if selectedTab == 3 {
                selectedTab = 0
            }
            try? Tips.configure([
                .displayFrequency(.immediate),
                .datastoreLocation(.applicationDefault)
            ])
        }
        .adaptiveTabBottomAccessory()
    }

}
