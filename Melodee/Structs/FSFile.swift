//
//  FSFile.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2023/09/11.
//

import Foundation
import SwiftUI

struct FSFile: FilesystemObject {

    var name: String
    var `extension`: String
    var path: String
    var type: FileType
    var playbackQueueID: String = ""

    func hash(into hasher: inout Hasher) {
        hasher.combine(path)
    }

    func containingFolderPath() -> String {
        let url = URL(filePath: path)
        return url.deletingLastPathComponent().path(percentEncoded: false)
    }

    func containingFolderName() -> String {
        let url = URL(filePath: containingFolderPath())
        return url.lastPathComponent
    }
}
