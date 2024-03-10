//
//  Playlist.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2024/03/10.
//

import Foundation

struct Playlist: Codable {
    var id: String = UUID().uuidString
    var name: String
    var items: [PlaylistItem]
}
