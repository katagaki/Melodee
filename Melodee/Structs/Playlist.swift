//
//  Playlist.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2024/03/10.
//

import Foundation

struct Playlist: Identifiable, Equatable, Hashable, Codable {
    var id: String = UUID().uuidString
    var name: String
    var items: [PlaylistItem]?

    func playlistItems() -> [PlaylistItem] {
        if let items {
            return items
        } else {
            return []
        }
    }

    func playlistItemCount() -> Int {
        if let items {
            return items.count
        } else {
            return 0
        }
    }

    mutating func append(_ item: PlaylistItem) {
        if items != nil {
            self.items?.append(item)
        } else {
            self.items = []
            self.items?.append(item)
        }
    }

    static func == (lhs: Playlist, rhs: Playlist) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine([id, name])
    }

}
