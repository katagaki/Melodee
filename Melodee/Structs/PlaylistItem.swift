//
//  PlaylistItem.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2024/03/10.
//

import Foundation

struct PlaylistItem: Codable, Identifiable {
    var id: Int { order }
    var order: Int
    var path: String
}
