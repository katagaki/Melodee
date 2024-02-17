//
//  SettingsManager.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2023/09/13.
//

import Foundation

class SettingsManager: ObservableObject {

    let defaults = UserDefaults.standard

    init() {
        // Set default settings

        // Load configuration into global variables
    }

    func set(_ value: Any?, forKey key: String) {
        defaults.set(value, forKey: key)
    }
}
