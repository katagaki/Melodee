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

        let playlistFiles = audioFiles.compactMap { file -> PlaylistFile? in
            guard let relativePath = relativePath(
                from: directoryURL,
                to: URL(fileURLWithPath: file.path)
            ) else { return nil }
            return PlaylistFile(relativePath: relativePath)
        }
        let playlist = Playlist(name: name, files: playlistFiles)
        save(playlist, to: fileURL)
        return fileURL
    }

    /// Computes a relative path from a directory to a file.
    static func relativePath(from base: URL, to target: URL) -> String? {
        let basePath = base.standardizedFileURL.path(percentEncoded: false)
        let targetPath = target.standardizedFileURL.path(percentEncoded: false)

        let baseComponents = basePath.split(separator: "/", omittingEmptySubsequences: true)
        let targetComponents = targetPath.split(separator: "/", omittingEmptySubsequences: true)

        // Find common prefix length
        var commonLength = 0
        while commonLength < baseComponents.count && commonLength < targetComponents.count
                && baseComponents[commonLength] == targetComponents[commonLength] {
            commonLength += 1
        }

        // Number of ".." needed to go up from base
        let ups = baseComponents.count - commonLength
        var parts: [String] = Array(repeating: "..", count: ups)
        // Append remaining target components
        parts.append(contentsOf: targetComponents[commonLength...].map(String.init))

        let result = parts.joined(separator: "/")
        return result.isEmpty ? nil : result
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
