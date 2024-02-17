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
            TabView(selection: $tabManager.selectedTab) {
                NavigationStack(path: $navigationManager.filesTabPath) {
                    FileBrowserView()
                }
                .tabItem {
                    Label("TabTitle.Files", image: "Tab.FileBrowser")
                }
                .toolbarBackground(.hidden, for: .tabBar)
                .tag(TabType.fileManager)
                .overlay {
                    ZStack(alignment: .bottom) {
                        Color.clear
                        NowPlayingBar()
                            .onTapGesture {
                                isNowPlayingSheetPresented.toggle()
                            }
                            .gesture(
                                DragGesture()
                                    .onEnded { value in
                                        if value.translation.height <= -25 {
                                            isNowPlayingSheetPresented.toggle()
                                        }
                                    }
                            )
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
