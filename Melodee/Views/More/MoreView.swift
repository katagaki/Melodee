//
//  MoreView.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2023/09/11.
//

import SwiftUI

struct MoreView: View {

    @EnvironmentObject var navigationManager: NavigationManager
    @EnvironmentObject var settings: SettingsManager

    var body: some View {
        NavigationStack(path: $navigationManager.moreTabPath) {
            List {
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
                Section {
                    Link(destination: URL(string: "https://x.com/katagaki_")!) {
                        HStack {
                            ListRow(image: "ListIcon.Twitter",
                                    title: "More.Help.Twitter",
                                    subtitle: "More.Help.Twitter.Subtitle",
                                    includeSpacer: true)
                            Image(systemName: "safari")
                                .opacity(0.5)
                        }
                        .foregroundColor(.primary)
                    }
                    Link(destination: URL(string: "mailto:ktgk.public@icloud.com")!) {
                        HStack {
                            ListRow(image: "ListIcon.Email",
                                    title: "More.Help.Email",
                                    subtitle: "More.Help.Email.Subtitle",
                                    includeSpacer: true)
                            Image(systemName: "arrow.up.forward.app")
                                .opacity(0.5)
                        }
                        .foregroundColor(.primary)
                    }
                    Link(destination: URL(string: "https://github.com/katagaki/Melodee")!) {
                        HStack {
                            ListRow(image: "ListIcon.GitHub",
                                    title: "More.Help.GitHub",
                                    subtitle: "More.Help.GitHub.Subtitle",
                                    includeSpacer: true)
                            Image(systemName: "safari")
                                .opacity(0.5)
                        }
                        .foregroundColor(.primary)
                    }
                } header: {
                    ListSectionHeader(text: "More.Help")
                        .font(.body)
                }
                Section {
                    NavigationLink(value: ViewPath.moreAttributions) {
                        ListRow(image: "ListIcon.Attributions",
                                title: "More.Attribution")
                    }
                }
            }
            .listStyle(.insetGrouped)
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
            .navigationTitle("ViewTitle.More")
        }
    }
}
