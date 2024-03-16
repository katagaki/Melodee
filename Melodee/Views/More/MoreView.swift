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

    var body: some View {
        NavigationStack(path: $navigationManager.moreTabPath) {
            MoreList(repoName: "katagaki/Melodee", viewPath: ViewPath.moreAttributions) {
                Section {
                    NavigationLink(value: ViewPath.moreCloudSync) {
                        ListRow(image: "ListIcon.iCloud", title: "iCloud")
                    }
                } header: {
                    ListSectionHeader(text: "More.General")
                        .font(.body)
                }
            }
            .navigationDestination(for: ViewPath.self, destination: { viewPath in
                switch viewPath {
                case .moreCloudSync: HStack {}
                case .moreAttributions: LicensesView()
                default: Color.clear
                }
            })
        }
    }
}
