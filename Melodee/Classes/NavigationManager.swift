//
//  NavigationManager.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2023/09/11.
//

import Foundation

class NavigationManager: ObservableObject {

    @Published var filesTabPath: [ViewPath] = []
    @Published var playlistsTabPath: [ViewPath] = []
    @Published var moreTabPath: [ViewPath] = []

    func popToRoot(for tab: TabType) {
        switch tab {
        case .fileManager:
            filesTabPath.removeAll()
        case .playlists:
            playlistsTabPath.removeAll()
        case .more:
            moreTabPath.removeAll()
        }
    }

    func push(_ viewPath: ViewPath, for tab: TabType) {
        switch tab {
        case .fileManager:
            filesTabPath.append(viewPath)
        case .playlists:
            playlistsTabPath.append(viewPath)
        case .more:
            moreTabPath.append(viewPath)
        }
    }

}
