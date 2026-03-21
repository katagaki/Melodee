//
//  PlaylistItem.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2024/03/16.
//

import Foundation
import SwiftData

@Model
final class Playlist {
    var name: String
    @Relationship(deleteRule: .cascade, inverse: \PlaylistFileBookmark.playlist)
    var fileBookmarks: [PlaylistFileBookmark]

    init(name: String) {
        self.name = name
        self.fileBookmarks = []
    }

    /// Returns bookmarks sorted by their order index
    var sortedBookmarks: [PlaylistFileBookmark] {
        fileBookmarks.sorted { $0.order < $1.order }
    }

    /// Resolves all file bookmarks into FSFile objects, skipping any that fail to resolve.
    func resolveFiles() -> [FSFile] {
        var results: [FSFile] = []
        for bookmark in sortedBookmarks {
            if let file = bookmark.resolveFile() {
                results.append(file)
            }
        }
        return results
    }

    /// Returns the first taggable audio file (MP3 or M4A) for album art, or nil if none exist.
    func firstTaggableAudioFile() -> FSFile? {
        for bookmark in sortedBookmarks {
            if let file = bookmark.resolveFile(), file.isTaggableAudio() {
                return file
            }
        }
        return nil
    }

    /// Adds a file bookmark at the end of the playlist
    func addFile(url: URL) throws {
        let bookmarkData = try url.bookmarkData(
            options: .minimalBookmark,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
        let nextOrder = (fileBookmarks.map(\.order).max() ?? -1) + 1
        let fileName = url.deletingPathExtension().lastPathComponent
        let fileExtension = url.pathExtension.lowercased()
        let bookmark = PlaylistFileBookmark(
            order: nextOrder,
            bookmarkData: bookmarkData,
            fileName: fileName,
            fileExtension: fileExtension
        )
        fileBookmarks.append(bookmark)
    }

    // MARK: - JSON Export/Import

    /// Exports this playlist to a portable JSON representation.
    func toJSON() -> PlaylistJSON {
        let items = sortedBookmarks.compactMap { bookmark -> PlaylistJSON.Item? in
            guard let url = bookmark.resolveURL() else { return nil }
            return PlaylistJSON.Item(
                fileName: bookmark.fileName,
                fileExtension: bookmark.fileExtension,
                relativePath: url.lastPathComponent,
                order: bookmark.order
            )
        }
        return PlaylistJSON(name: name, items: items)
    }

    /// Imports files from a JSON representation, resolving paths relative to baseURL.
    func importFromJSON(_ json: PlaylistJSON, baseURL: URL) {
        for item in json.items {
            let fileURL = baseURL.appendingPathComponent(
                "\(item.fileName).\(item.fileExtension)"
            )
            if FileManager.default.fileExists(atPath: fileURL.path(percentEncoded: false)) {
                try? addFile(url: fileURL)
            }
        }
    }

    // MARK: - M3U8 Export/Import

    /// Exports this playlist to M3U8 format with relative paths only.
    func toM3U8() -> String {
        var lines: [String] = ["#EXTM3U", "#PLAYLIST:\(name)"]
        for bookmark in sortedBookmarks {
            guard let url = bookmark.resolveURL() else { continue }
            let filename = url.lastPathComponent
            lines.append("#EXTINF:-1,\(bookmark.fileName)")
            lines.append(filename)
        }
        return lines.joined(separator: "\n") + "\n"
    }

    /// Imports files from M3U8 content, resolving relative paths against baseURL.
    /// Only relative paths are supported; absolute paths are skipped.
    static func fromM3U8(content: String, baseURL: URL) -> (name: String?, relativePaths: [String]) {
        var name: String?
        var paths: [String] = []

        for line in content.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty || trimmed.hasPrefix("#EXTINF") {
                continue
            }
            if trimmed.hasPrefix("#PLAYLIST:") {
                name = String(trimmed.dropFirst("#PLAYLIST:".count))
                continue
            }
            if trimmed.hasPrefix("#") {
                continue
            }
            // Skip absolute paths
            if trimmed.hasPrefix("/") || trimmed.contains("://") {
                continue
            }
            paths.append(trimmed)
        }
        return (name, paths)
    }
}

@Model
final class PlaylistFileBookmark {
    var order: Int
    var bookmarkData: Data
    var fileName: String
    var fileExtension: String
    var playlist: Playlist?

    init(order: Int, bookmarkData: Data, fileName: String, fileExtension: String) {
        self.order = order
        self.bookmarkData = bookmarkData
        self.fileName = fileName
        self.fileExtension = fileExtension
    }

    /// Resolves the bookmark data into a URL, re-saving if stale.
    /// Returns nil if the bookmark cannot be resolved or the file doesn't exist.
    func resolveURL() -> URL? {
        do {
            var isStale = false
            let url = try URL(
                resolvingBookmarkData: bookmarkData,
                options: .withoutUI,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
            if isStale {
                // Re-save the bookmark data
                if let newBookmarkData = try? url.bookmarkData(
                    options: .minimalBookmark,
                    includingResourceValuesForKeys: nil,
                    relativeTo: nil
                ) {
                    bookmarkData = newBookmarkData
                }
            }
            guard FileManager.default.fileExists(atPath: url.path(percentEncoded: false)) else {
                return nil
            }
            return url
        } catch {
            debugPrint("Failed to resolve bookmark: \(error.localizedDescription)")
            return nil
        }
    }

    /// Resolves the bookmark into an FSFile, or returns nil on failure.
    func resolveFile() -> FSFile? {
        guard let url = resolveURL() else { return nil }
        let fileExtension = url.pathExtension.lowercased()
        let fileType = FilesystemManager.fileType(forExtension: fileExtension)
        return FSFile(
            name: url.deletingPathExtension().lastPathComponent,
            extension: fileExtension,
            path: url.path(percentEncoded: false),
            type: fileType
        )
    }
}

// MARK: - Portable JSON Representation

struct PlaylistJSON: Codable {
    var name: String
    var items: [Item]

    struct Item: Codable {
        var fileName: String
        var fileExtension: String
        var relativePath: String
        var order: Int
    }
}
