//
//  PlaylistItem.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2024/03/16.
//

import Foundation

struct Playlist: Codable {
    var name: String
    var files: [PlaylistFile]

    init(name: String, files: [PlaylistFile] = []) {
        self.name = name
        self.files = files
    }

    // MARK: - M3U8 Export

    func toM3U8() -> String {
        var lines: [String] = ["#EXTM3U", "#PLAYLIST:\(name)"]
        for file in files {
            let fileName = URL(fileURLWithPath: file.relativePath)
                .deletingPathExtension().lastPathComponent
            lines.append("#EXTINF:-1,\(fileName)")
            lines.append(file.relativePath)
        }
        return lines.joined(separator: "\n") + "\n"
    }

    // MARK: - M3U8 Import

    static func fromM3U8(content: String) -> (name: String?, relativePaths: [String]) {
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

struct PlaylistFile: Codable, Identifiable, Hashable {
    var relativePath: String

    var id: String { relativePath }

    var fileName: String {
        URL(fileURLWithPath: relativePath).deletingPathExtension().lastPathComponent
    }

    var fileExtension: String {
        URL(fileURLWithPath: relativePath).pathExtension.lowercased()
    }

    func resolve(relativeTo baseURL: URL) -> FSFile? {
        let fileURL = baseURL.appendingPathComponent(relativePath)
        guard FileManager.default.fileExists(atPath: fileURL.path(percentEncoded: false)) else {
            return nil
        }
        let ext = fileURL.pathExtension.lowercased()
        let fileType = FilesystemManager.fileType(forExtension: ext)
        return FSFile(
            name: fileURL.deletingPathExtension().lastPathComponent,
            extension: ext,
            path: fileURL.path(percentEncoded: false),
            type: fileType
        )
    }
}
