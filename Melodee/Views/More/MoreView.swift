//
//  MoreView.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2023/09/11.
//

import Komponents
import SwiftUI

struct MoreView: View {

    @Environment(NavigationManager.self) var navigationManager

    var body: some View {
        @Bindable var navigationManager = navigationManager
        NavigationStack(path: $navigationManager.moreTabPath) {
            MoreList(repoName: "katagaki/Melodee", viewPath: ViewPath.moreAttributions) { }
            .navigationDestination(for: ViewPath.self, destination: { viewPath in
                switch viewPath {
                case .moreAttributions: LicensesView()
                default: Color.clear
                }
            })
        }
    }
}
