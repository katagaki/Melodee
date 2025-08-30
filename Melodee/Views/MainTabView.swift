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

    @Namespace var namespace

    var body: some View {
        @Bindable var nowPlayingBarManager = nowPlayingBarManager

        TabView {
            Tab("Tab.Local", systemImage: "iphone") {
                NavigationStack(path: $localFilesTabPath) {
                    FolderView(
                        currentDirectory: nil,
                        overrideStorageLocation: .local
                    )
                    .hasFileBrowserNavigationDestinations()
                }
            }
            if FileManager.default.ubiquityIdentityToken != nil {
                Tab("Tab.Cloud", systemImage: "cloud.fill") {
                    NavigationStack(path: $cloudFilesTabPath) {
                        FolderView(
                            currentDirectory: nil,
                            overrideStorageLocation: .cloud
                        )
                        .hasFileBrowserNavigationDestinations()
                    }
                }
            }
            Tab("Tab.Library", systemImage: "music.note.square.stack.fill") {
                FilesView()
            }
            Tab("Tab.More", systemImage: "ellipsis") {
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
                .matchedTransitionSource(id: "NowPlayingBar", in: namespace)
        }
        .sheet(isPresented: $nowPlayingBarManager.isSheetPresented) {
            NowPlayingView()
                .navigationTransition(
                    .zoom(sourceID: "NowPlayingBar", in: namespace)
                )
        }
    }
}
