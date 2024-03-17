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
        if defaults.bool(forKey: "CloudStoresPlaylists") && FileManager.default.ubiquityIdentityToken != nil {
            self.playlists = PlaylistManager.playlists(from: .cloud)
        } else {
            self.playlists = PlaylistManager.playlists(from: .local)
        }
    }

    func create(_ name: String) {
        playlists.append(Playlist(name: name, items: []))
        save(to: .cloud)
    }

    func create(_ name: String, with items: [String]) {
        var newPlaylist = Playlist(name: name, items: [])
        for index in 0..<items.count {
            newPlaylist.append(PlaylistItem(order: index, path: items[index]))
        }
        save(to: .cloud)
    }

    func add(_ filePath: String, to playlistID: String) {
        if let playlistIndex = playlists.firstIndex(where: { $0.id == playlistID }) {
            let orderNumber = playlists[playlistIndex].playlistItemCount()
            playlists[playlistIndex].append(PlaylistItem(order: orderNumber, path: filePath))
            save(to: .cloud)
        }
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
                debugPrint("Saving playlists to On My Device")
                if let documentsDirectoryURL = PlaylistManager.localStorageLocationPath(),
                   manager.createFile(atPath: "\(documentsDirectoryURL.path())Playlists.json",
                                      contents: playlistsJSONString.data(using: .utf8)) {
                    debugPrint("Saved playlists to On My Device")
                } else {
                    debugPrint("Error while saving playlists")
                }
            case .cloud:
                debugPrint("Saving playlists to iCloud")
                if let cloudStorageLocationPath = PlaylistManager.cloudStorageLocationPath() {
                    let playlistsURL = URL(filePath: cloudStorageLocationPath.path(percentEncoded: false))
                        .appending(path: "Playlists.json")
                    NSFileCoordinator().coordinate(writingItemAt: playlistsURL, error: .none) { url in
                        if manager.createFile(atPath: url.path(percentEncoded: false),
                                              contents: playlistsJSONString.data(using: .utf8)) {
                            debugPrint("Saved playlists to iCloud")
                        } else {
                            debugPrint("Error while saving playlists to iCloud")
                        }
                    }
                } else {
                    debugPrint("Error while saving playlists to iCloud, trying On My Device")
                    save(to: .local)
                }
            case .external:
                debugPrint("Not implemented")
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
            let semaphore = DispatchSemaphore(value: 0)
            if let cloudStorageLocationPath = cloudStorageLocationPath() {
                let playlistsURL = URL(filePath: cloudStorageLocationPath.path(percentEncoded: false))
                    .appending(path: "Playlists.json")
                var playlists: [Playlist] = []
                NSFileCoordinator().coordinate(readingItemAt: playlistsURL, error: .none) { url in
                    debugPrint("Loading playlists JSON from iCloud")
                    playlists = PlaylistManager.playlists(atPath: url.path(percentEncoded: false)) ?? []
                    semaphore.signal()
                }
                semaphore.wait()
                return playlists
            } else {
                debugPrint("Could not load playlists JSON from iCloud, trying On My Device")
                return playlists(from: .local)
            }
        case .external:
            debugPrint("Not implemented")
            return []
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
