//
//  SettingsManager.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2023/09/13.
//

import Foundation

class SettingsManager: ObservableObject {

    let defaults = UserDefaults.standard

    @Published var showNowPlayingBar: Bool = true
    @Published var showNowPlayingTab: Bool = false

    init() {
        // Set default settings
        if defaults.value(forKey: "ShowNowPlayingBar") == nil {
            defaults.set(true, forKey: "ShowNowPlayingBar")
        }
        if defaults.value(forKey: "ShowNowPlayingTab") == nil {
            defaults.set(false, forKey: "ShowNowPlayingTab")
        }

        // Load configuration into global variables
        showNowPlayingBar = defaults.bool(forKey: "ShowNowPlayingBar")
        showNowPlayingTab = defaults.bool(forKey: "ShowNowPlayingTab")
    }

    func set(_ value: Any?, forKey key: String) {
        defaults.set(value, forKey: key)
    }

    func setShowNowPlayingBar(_ newValue: Bool) {
        defaults.set(newValue, forKey: "ShowNowPlayingBar")
        showNowPlayingBar = newValue
    }

    func setShowNowPlayingTab(_ newValue: Bool) {
        defaults.set(newValue, forKey: "ShowNowPlayingTab")
        showNowPlayingTab = newValue
    }

}
