//
//  FilesystemManager.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2023/09/11.
//

import Foundation

class FilesystemManager: ObservableObject {

    let manager = FileManager.default
    var documentsDirectory: String?

    @Published var files: [any FilesystemObject] = []

    init() {
        do {
            let placeholderFilename = NSLocalizedString("Shared.DropFilesFileName",
                                                        comment: "")
            let documentsDirectoryURL = try FileManager.default
                .url(for: .documentDirectory,
                     in: .userDomainMask,
                     appropriateFor: nil,
                     create: true)
            self.documentsDirectory = documentsDirectoryURL.absoluteString
            manager
                .createFile(atPath: "\(documentsDirectoryURL.path())\(placeholderFilename)",
                            contents: "".data(using: .utf8))
        } catch {
            debugPrint(error.localizedDescription)
            documentsDirectory = ""
        }
    }

    func files(in subPath: String = "") -> [any FilesystemObject] {
        debugPrint("Enumerating files in '\(subPath)' (blank if root).")
        do {
            if let documentsDirectory = documentsDirectory,
               let documentsDirectoryURL = URL(string: documentsDirectory) {
                let pathToEnumerate = subPath == "" ? documentsDirectoryURL : URL(string: subPath)!
                return try manager
                    .contentsOfDirectory(at: pathToEnumerate,
                                         includingPropertiesForKeys: [.isRegularFileKey, .isDirectoryKey],
                                         options: [.skipsHiddenFiles]).compactMap { url in
                        if url.hasDirectoryPath {
                            return FSDirectory(name: url.lastPathComponent,
                                               path: url.path,
                                               files: files(in: url.path(percentEncoded: true)))
                        } else {
                            let fileExtension = url.pathExtension.lowercased()
                            switch fileExtension {
                            case "mp3", "m4a", "wav", "alac":
                                return FSFile(name: url.lastPathComponent,
                                              path: url.path)
                            default: break
                            }
                        }
                        return nil
                    }
            }
        } catch {
            debugPrint(error.localizedDescription)
        }
        return []
    }
}
