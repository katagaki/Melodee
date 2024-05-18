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

    @EnvironmentObject var navigationManager: NavigationManager
    @Environment(NowPlayingBarManager.self) var nowPlayingBarManager: NowPlayingBarManager

    @State var isNowPlayingSheetPresented: Bool = false

    var body: some View {
        ZStack {
            FilesView()
            .overlay {
                ZStack(alignment: .bottom) {
                    if !nowPlayingBarManager.isKeyboardShowing {
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
                if !nowPlayingBarManager.isKeyboardShowing {
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
    }
}
