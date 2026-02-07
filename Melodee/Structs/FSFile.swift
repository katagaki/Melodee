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
        do {
            let url = URL(filePath: containingFolderPath())
            if url.lastPathComponent == "Documents" {
                let documentsDirectoryURL = try FileManager.default
                .url(for: .documentDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true)
                if documentsDirectoryURL != url {
                    return url.lastPathComponent
                }
            } else {
                return url.lastPathComponent
            }
        } catch {
            debugPrint(error.localizedDescription)
        }
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? ""
    }

    /// Returns true if this file is a taggable audio file (MP3 or M4A)
    func isTaggableAudio() -> Bool {
        return self.extension == "mp3" || self.extension == "m4a"
    }

    /// Returns true if this audio file can be converted to other formats
    func isConvertibleAudio() -> Bool {
        let convertibleFormats = ["mp3", "m4a", "wav", "alac"]
        return convertibleFormats.contains(self.extension)
    }

    /// Returns available conversion formats for this audio file
    func availableConversionFormats() -> [String] {
        return AudioConverter.availableFormats(for: self.extension)
    }
}
