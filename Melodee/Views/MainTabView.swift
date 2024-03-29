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
    @Environment(NowPlayingBarManager.self) var nowPlayingBarManager: NowPlayingBarManager

    @State var isNowPlayingSheetPresented: Bool = false

    var body: some View {
        TabView(selection: $tabManager.selectedTab) {
            Group {
                FilesView()
                .tabItem {
                    Label("TabTitle.Files", image: "Tab.FileBrowser")
                }
                .tag(TabType.fileManager)
                MoreView()
                    .tabItem {
                        Label("TabTitle.More", systemImage: "ellipsis")
                    }
                    .tag(TabType.more)
            }
            .toolbarBackground(.hidden, for: .tabBar)
            .overlay {
                ZStack(alignment: .bottom) {
                    if !nowPlayingBarManager.keyboardShowing {
                        Color.clear
                        Color.clear
                            .frame(maxWidth: .infinity, minHeight: 62.0, maxHeight: 62.0)
                            .background(.regularMaterial)
                    }
                }
            }
        }
        .overlay {
            ZStack(alignment: .bottom) {
                if !nowPlayingBarManager.keyboardShowing {
                    Color.clear
                    NowPlayingBar()
                        .contentShape(Rectangle())
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
                        .safeAreaPadding(.bottom, 50.0)
                }
            }
        }
        .sheet(isPresented: $isNowPlayingSheetPresented, content: {
            NowPlayingView()
                .presentationDragIndicator(.visible)
        })
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
