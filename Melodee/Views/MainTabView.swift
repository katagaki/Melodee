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
            Tab("Tab.ExternalFolder", systemImage: "folder.fill", value: 2) {
                FilesView()
            }
            Tab("Tab.More", systemImage: "ellipsis", value: 3) {
                MoreView()
            }
        }
        .task {
            try? Tips.configure([
                .displayFrequency(.immediate),
                .datastoreLocation(.applicationDefault)
            ])
        }
        .tabViewBottomAccessory {
            NowPlayingBar()
                .popoverTip(NPQueueTip(), arrowEdge: .bottom)
                .onTapGesture {
                    self.nowPlayingBarManager.isSheetPresented.toggle()
                }
        }
        .sheet(isPresented: $nowPlayingBarManager.isSheetPresented) {
            NowPlayingView()
        }
    }
}
