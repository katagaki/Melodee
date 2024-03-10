//
//  PlaylistManager.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2024/03/10.
//

import Foundation

@Observable
class PlaylistManager {

    @ObservationIgnored let manager = FileManager.default
    @ObservationIgnored var defaults = UserDefaults.standard

    var playlists: [Playlist]

    init() {
        self.playlists = PlaylistManager.cloudPlaylists()
    }

    static func localPlaylists() -> [Playlist] {
        if let documentsDirectoryURL = try? FileManager.default
            .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true),
            let playlists = playlists(atPath: "\(documentsDirectoryURL.path())Playlists.json") {
            return playlists
        } else {
            return []
        }
    }

    static func cloudPlaylists() -> [Playlist] {
        if let cloudDocumentsDirectoryURL = FileManager.default
                .url(forUbiquityContainerIdentifier: nil)?
                .appendingPathComponent("Documents"),
           let playlists = playlists(atPath: "\(cloudDocumentsDirectoryURL.path())Playlists.json") {
            return playlists
        } else {
            return localPlaylists()
        }
    }

    static func playlists(atPath playlistsPath: String) -> [Playlist]? {
        if FileManager.default.fileExists(atPath: playlistsPath),
           let jsonString = try? String(contentsOfFile: playlistsPath),
           let jsonData = jsonString.data(using: .utf8),
           let decodedPlaylists: [Playlist] = try? JSONDecoder().decode([Playlist].self, from: jsonData) {
            return decodedPlaylists
        } else {
            return nil
        }
    }
}
