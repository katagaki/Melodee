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
        self.playlists = PlaylistManager.playlists(from: .cloud)
    }

    func create(_ name: String) {
        playlists.append(Playlist(name: name, items: []))
        save(to: .cloud)
    }

    func create(_ name: String, with items: [String]) {
        var newPlaylist = Playlist(name: name, items: [])
        for index in 0..<items.count {
            newPlaylist.items.append(PlaylistItem(order: index, path: items[index]))
        }
        save(to: .cloud)
    }

    func delete(id: String) {
        playlists.removeAll(where: { $0.id == id })
        save(to: .cloud)
    }

    func save(to storageLocation: StorageLocation) {
        if let playlistsJSONData = try? JSONEncoder().encode(playlists),
           let playlistsJSONString =  String(data: playlistsJSONData, encoding: .utf8) {
            switch storageLocation {
            case .local:
                if let documentsDirectoryURL = PlaylistManager.localStorageLocationPath() {
                    debugPrint("Saving playlists to On My Device")
                    manager.createFile(atPath: "\(documentsDirectoryURL.path())Playlists.json",
                                       contents: playlistsJSONString.data(using: .utf8))
                } else {
                    debugPrint("Error while saving playlists")
                }
            case .cloud:
                if let cloudDocumentsDirectoryURL = PlaylistManager.cloudStorageLocationPath() {
                    debugPrint("Saving playlists to iCloud")
                    manager.createFile(atPath: "\(cloudDocumentsDirectoryURL.path())Playlists.json",
                                       contents: playlistsJSONString.data(using: .utf8))
                } else {
                    debugPrint("Error while saving playlists to iCloud, trying On My Device")
                    save(to: .local)
                }
            }
        } else {
            debugPrint("Error while encoding playlists")
        }
    }

    static func localStorageLocationPath() -> URL? {
        return try? FileManager.default
            .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    }

    static func cloudStorageLocationPath() -> URL? {
        return FileManager.default
            .url(forUbiquityContainerIdentifier: nil)?
            .appendingPathComponent("Documents")
    }

    static func playlists(from storageLocation: StorageLocation) -> [Playlist] {
        switch storageLocation {
        case .local:
            if let documentsDirectoryURL = localStorageLocationPath(),
                let playlists = playlists(atPath: "\(documentsDirectoryURL.path())Playlists.json") {
                debugPrint("Loading playlists JSON from On My Device")
                return playlists
            } else {
                debugPrint("Could not load playlists JSON, starting from scratch")
                return []
            }
        case .cloud:
            if let cloudDocumentsDirectoryURL = cloudStorageLocationPath(),
               let playlists = playlists(atPath: "\(cloudDocumentsDirectoryURL.path())Playlists.json") {
                debugPrint("Loading playlists JSON from iCloud")
                return playlists
            } else {
                debugPrint("Could not load playlists JSON from iCloud, trying On My Device")
                return playlists(from: .local)
            }
        }
    }

    static func playlists(atPath playlistsPath: String) -> [Playlist]? {
        if FileManager.default.fileExists(atPath: playlistsPath),
           let jsonString = try? String(contentsOfFile: playlistsPath),
           let jsonData = jsonString.data(using: .utf8),
           let playlists: [Playlist] = try? JSONDecoder().decode([Playlist].self, from: jsonData) {
            return playlists
        } else {
            return nil
        }
    }
}
