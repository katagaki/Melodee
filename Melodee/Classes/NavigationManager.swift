//
//  NavigationManager.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2023/09/11.
//

import Foundation

class NavigationManager: ObservableObject {

    @Published var filesTabPath: [ViewPath] = []
    @Published var nowPlayingTabPath: [ViewPath] = []
    @Published var moreTabPath: [ViewPath] = []

    func popToRoot(for tab: TabType) {
        switch tab {
        case .fileManager:
            filesTabPath.removeAll()
        case .nowPlaying:
            nowPlayingTabPath.removeAll()
        case .more:
            moreTabPath.removeAll()
        }
    }

    func push(_ viewPath: ViewPath, for tab: TabType) {
        switch tab {
        case .fileManager:
            filesTabPath.append(viewPath)
        case .nowPlaying:
            nowPlayingTabPath.append(viewPath)
        case .more:
            moreTabPath.append(viewPath)
        }
    }

}
