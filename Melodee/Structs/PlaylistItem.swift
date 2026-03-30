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
