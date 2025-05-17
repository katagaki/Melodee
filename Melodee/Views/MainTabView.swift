//
//  MainTabView.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2023/09/11.
//

import LNPopupUI
import SwiftUI
import TipKit

struct MainTabView: View {

    @EnvironmentObject var navigationManager: NavigationManager
    @Environment(NowPlayingBarManager.self) var nowPlayingBarManager: NowPlayingBarManager

    @State var isNowPlayingBarPresented: Bool = true
    @State var isNowPlayingSheetPresented: Bool = false

    var body: some View {
        FilesView()
            .popup(isBarPresented: $isNowPlayingBarPresented, isPopupOpen: $isNowPlayingSheetPresented) {
                NowPlayingView()
            }
            .popupBarCustomView(wantsDefaultTapGesture: true, wantsDefaultPanGesture: true) {
                NowPlayingBar()
                    .popoverTip(NPQueueTip(), arrowEdge: .bottom)
            }
            .popupInteractionStyle(.drag)
            .task {
                try? Tips.configure([
                    .displayFrequency(.immediate),
                    .datastoreLocation(.applicationDefault)
                ])
            }
    }
}
