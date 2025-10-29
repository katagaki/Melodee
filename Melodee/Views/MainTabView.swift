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
    @State var externalFolderTabTitle: String = ""

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
            Tab(value: 2) {
                FilesView(externalFolderTabTitle: $externalFolderTabTitle)
            } label: {
                Label(externalFolderTabTitle.isEmpty ? NSLocalizedString("Tab.ExternalFolder", comment: "") : externalFolderTabTitle, systemImage: "folder.fill")
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
        .adaptiveTabBottomAccessory(isPopupPresented: $nowPlayingBarManager.isSheetPresented) {
            // Bar content
            NowPlayingBar()
                .popoverTip(NPQueueTip(), arrowEdge: .bottom)
                .onTapGesture {
                    self.nowPlayingBarManager.isSheetPresented.toggle()
                }
                .matchedTransitionSource(id: "NowPlayingBar", in: namespace)
        } popupContent: {
            // Popup content
            if #available(iOS 26.0, *) {
                NowPlayingView()
                    .navigationTransition(
                        .zoom(sourceID: "NowPlayingBar", in: namespace)
                    )
            } else {
                NowPlayingView()
            }
        }
    }

    func externalFolderTabTitleFormatted() -> String {
        if externalFolderTabTitle.isEmpty {
            return NSLocalizedString("Tab.ExternalFolder", comment: "")
        } else {
            if externalFolderTabTitle.count >= 15 {
                return NSLocalizedString("Tab.ExternalFolder", comment: "")
            } else {
                return externalFolderTabTitle
            }
        }
    }
}
