//
//  NavigationManager.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2023/09/11.
//

import Foundation

class NavigationManager: ObservableObject {

    @Published var viewPath: [ViewPath] = []

    func popToRoot() {
        viewPath.removeAll()
    }

    func push(_ viewPath: ViewPath) {
        self.viewPath.append(viewPath)
    }

}
