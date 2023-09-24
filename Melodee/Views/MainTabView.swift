//
//  MainTabView.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2023/09/11.
//

import MarqueeText
import SwiftUI
import TipKit

struct MainTabView: View {

    @EnvironmentObject var tabManager: TabManager
    @EnvironmentObject var navigationManager: NavigationManager
    @EnvironmentObject var settings: SettingsManager
    @State var isNowPlayingSheetPresented: Bool = false

    var body: some View {
        Group {
            if settings.showNowPlayingTab {
                TabView(selection: $tabManager.selectedTab) {
                    NavigationStack(path: $navigationManager.filesTabPath) {
                        FileBrowserView()
                    }
                    .tabItem {
                        Label("TabTitle.Files", image: "Tab.FileBrowser")
                    }
                    .toolbarBackground(settings.showNowPlayingBar ? .hidden : .automatic, for: .tabBar)
                    .tag(TabType.fileManager)
                    .overlay {
                        ZStack(alignment: .bottom) {
                            Color.clear
                            if settings.showNowPlayingBar {
                                NowPlayingBar()
                                    .onTapGesture {
                                        tabManager.selectedTab = .nowPlaying
                                    }
                            }
                        }
                    }
                    NowPlayingView()
                        .tabItem {
                            Label("TabTitle.NowPlaying", image: "Tab.NowPlaying")
                        }
                        .tag(TabType.nowPlaying)
                    MoreView()
                        .tabItem {
                            Label("TabTitle.More", systemImage: "ellipsis")
                        }
                        .tag(TabType.more)
                }
            } else {
                TabView(selection: $tabManager.selectedTab) {
                    NavigationStack(path: $navigationManager.filesTabPath) {
                        FileBrowserView()
                    }
                    .tabItem {
                        Label("TabTitle.Files", image: "Tab.FileBrowser")
                    }
                    .toolbarBackground(settings.showNowPlayingBar ? .hidden : .automatic, for: .tabBar)
                    .tag(TabType.fileManager)
                    .overlay {
                        ZStack(alignment: .bottom) {
                            Color.clear
                            if settings.showNowPlayingBar {
                                NowPlayingBar()
                                    .onTapGesture {
                                        isNowPlayingSheetPresented.toggle()
                                    }
                            }
                        }
                    }
                    .sheet(isPresented: $isNowPlayingSheetPresented, content: {
                        NowPlayingView()
                            .presentationDragIndicator(.visible)
                    })
                    MoreView()
                        .tabItem {
                            Label("TabTitle.More", systemImage: "ellipsis")
                        }
                        .tag(TabType.more)
                }
            }
        }
        .task {
            try? Tips.configure([
                .displayFrequency(.immediate),
                .datastoreLocation(.applicationDefault)
            ])
        }
        .onReceive(tabManager.$selectedTab, perform: { newValue in
            if newValue == tabManager.previouslySelectedTab {
                navigationManager.popToRoot(for: newValue)
            }
            tabManager.previouslySelectedTab = newValue
        })
    }
}
