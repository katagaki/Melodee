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

    @AppStorage(wrappedValue: false, "CloudStoresPlaylists") var storePlaylistsInCloud: Bool
    @AppStorage(wrappedValue: false, "CloudStoresFiles") var storeFilesInCloud: Bool

    @State var isPendingMoveToiCloudPrompt: Bool = false

    var body: some View {
        NavigationStack(path: $navigationManager.moreTabPath) {
            MoreList(repoName: "katagaki/Melodee", viewPath: ViewPath.moreAttributions) {
                if FileManager.default.ubiquityIdentityToken != nil {
                    Section {
                        Toggle(isOn: $storeFilesInCloud, label: {
                            ListRow(image: "ListIcon.Cloud.Files",
                                    title: "Cloud.Stores.Files",
                                    includeSpacer: true)
                        })
                        Toggle(isOn: $storePlaylistsInCloud, label: {
                            ListRow(image: "ListIcon.Cloud.Playlists",
                                    title: "Cloud.Stores.Playlists",
                                    includeSpacer: true)
                        })
                    } header: {
                        ListSectionHeader(text: "More.CloudSync")
                            .font(.body)
                    }
                }
            }
            .sheet(isPresented: $isPendingMoveToiCloudPrompt) {
                MoreMoveToCloudView(storeFilesInCloud: $storeFilesInCloud)
                    .interactiveDismissDisabled()
            }
            .navigationDestination(for: ViewPath.self, destination: { viewPath in
                switch viewPath {
                case .moreAttributions: LicensesView()
                default: Color.clear
                }
            })
            .onChange(of: storeFilesInCloud) { oldValue, newValue in
                if !oldValue && newValue {
                    isPendingMoveToiCloudPrompt = true
                }
            }
        }
    }
}
