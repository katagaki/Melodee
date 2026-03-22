//
//  PlaylistManager.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2024/03/16.
//

import Foundation

@Observable
class PlaylistManager {

    static let playlistExtension = "melodee"

    // MARK: - Load / Save

    static func load(from url: URL) -> Playlist? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(Playlist.self, from: data)
    }

    static func save(_ playlist: Playlist, to url: URL) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(playlist) else { return }
        try? data.write(to: url, options: .atomic)
    }

    // MARK: - Create

    static func create(name: String, in directoryURL: URL, audioFiles: [FSFile]) -> URL {
        let sanitizedName = name.replacingOccurrences(of: "/", with: "-")
        let fileURL = directoryURL
            .appendingPathComponent(sanitizedName)
            .appendingPathExtension(playlistExtension)

        let playlistFiles = audioFiles.map { file in
            PlaylistFile(relativePath: "\(file.name).\(file.extension)")
        }
        let playlist = Playlist(name: name, files: playlistFiles)
        save(playlist, to: fileURL)
        return fileURL
    }

    // MARK: - Helpers

    static func directoryURL(for playlistFileURL: URL) -> URL {
        playlistFileURL.deletingLastPathComponent()
    }

    static func isPlaylistFile(_ url: URL) -> Bool {
        url.pathExtension.lowercased() == playlistExtension
    }

    static func isPlaylistFile(_ file: FSFile) -> Bool {
        file.extension.lowercased() == playlistExtension
    }
}
