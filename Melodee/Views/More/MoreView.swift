//
//  MoreView.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2023/09/11.
//

import Komponents
import SwiftUI

struct MoreView: View {

    @EnvironmentObject var navigationManager: NavigationManager
    @EnvironmentObject var settings: SettingsManager

    var body: some View {
        NavigationStack(path: $navigationManager.moreTabPath) {
            MoreList(repoName: "katagaki/Melodee", viewPath: ViewPath.moreAttributions) {
                Section {
                    Toggle(isOn: $settings.showNowPlayingBar, label: {
                        ListRow(image: "ListIcon.NowPlayingBar",
                                title: "More.General.ShowNowPlayingBar",
                                includeSpacer: true)
                    })
                    Toggle(isOn: $settings.showNowPlayingTab, label: {
                        ListRow(image: "ListIcon.NowPlayingTab",
                                title: "More.General.ShowNowPlayingTab",
                                includeSpacer: true)
                    })
                } header: {
                    ListSectionHeader(text: "More.General")
                        .font(.body)
                }
            }
            .navigationDestination(for: ViewPath.self, destination: { viewPath in
                switch viewPath {
                case .moreAttributions: LicensesView()
                default: Color.clear
                }
            })
            .onChange(of: settings.showNowPlayingBar, { _, newValue in
                settings.setShowNowPlayingBar(newValue)
            })
            .onChange(of: settings.showNowPlayingTab, { _, newValue in
                settings.setShowNowPlayingTab(newValue)
            })
        }
    }
}
