//
//  TabManager.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2023/09/11.
//

import SwiftUI

class TabManager: ObservableObject {
    @Published var selectedTab: TabType = .fileManager
    var previouslySelectedTab: TabType = .fileManager
}
