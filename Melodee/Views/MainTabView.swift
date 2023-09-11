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

    var body: some View {
        TabView(selection: $tabManager.selectedTab) {
            FileBrowserView()
                .tabItem {
                    Label("TabTitle.Files", image: "Tab.FileBrowser")
                }
                .toolbarBackground(.visible, for: .tabBar)
                .tag(TabType.fileManager)
            NowPlayingView()
                .tabItem {
                    Label("TabTitle.NowPlaying", systemImage: "list.triangle")
                }
                .toolbarBackground(.visible, for: .tabBar)
            MoreView()
                .tabItem {
                    Label("TabTitle.More", systemImage: "ellipsis")
                }
                .tag(TabType.more)
        }
        .task {
            if #available(iOS 17.0, *) {
                try? Tips.configure([
                    .displayFrequency(.immediate),
                    .datastoreLocation(.applicationDefault)
                ])
            }
        }
        .onReceive(tabManager.$selectedTab, perform: { newValue in
            if newValue == tabManager.previouslySelectedTab {
                navigationManager.popToRoot(for: newValue)
            }
            tabManager.previouslySelectedTab = newValue
        })
    }
}
