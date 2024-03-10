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
    @Environment(NavigationManager.self) var navigationManager

    @State var isNowPlayingSheetPresented: Bool = false

    var body: some View {
        @Bindable var navigationManager = navigationManager
        TabView(selection: $tabManager.selectedTab) {
            Group {
                NavigationStack(path: $navigationManager.filesTabPath) {
                    FileBrowserView()
                        .navigationDestination(for: ViewPath.self, destination: { viewPath in
                            switch viewPath {
                            case .fileBrowser(let directory): FileBrowserView(currentDirectory: directory)
                            case .imageViewer(let file): ImageViewerView(file: file)
                            case .textViewer(let file): TextViewerView(file: file)
                            case .pdfViewer(let file): PDFViewerView(file: file)
                            case .tagEditorSingle(let file): TagEditorView(files: [file])
                            case .tagEditorMultiple(let files): TagEditorView(files: files)
                            default: Color.clear
                            }
                        })
                }
                .tabItem {
                    Label("TabTitle.Files", image: "Tab.FileBrowser")
                }
                .tag(TabType.fileManager)
                PlaylistsView()
                    .tabItem {
                        Label("TabTitle.Playlists", systemImage: "music.note.list")
                    }
                    .tag(TabType.playlists)
                MoreView()
                    .tabItem {
                        Label("TabTitle.More", systemImage: "ellipsis")
                    }
                    .tag(TabType.more)
            }
            .toolbarBackground(.hidden, for: .tabBar)
            .overlay {
                ZStack(alignment: .bottom) {
                    Color.clear
                    Color.clear
                        .frame(maxWidth: .infinity, minHeight: 62.0, maxHeight: 62.0)
                        .background(.regularMaterial)
                }
            }
        }
        .overlay {
            ZStack(alignment: .bottom) {
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
