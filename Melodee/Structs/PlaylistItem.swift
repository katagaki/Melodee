//
//  PlaylistItem.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2024/03/16.
//

import Foundation

struct PlaylistItem: Codable, Identifiable {
    var id: String { self.order.description }
    var order: Int
    var path: String
}
