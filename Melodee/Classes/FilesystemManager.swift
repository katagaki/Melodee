//
//  FilesystemManager.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2023/09/11.
//

import Foundation
import SwiftUI
import ZIPFoundation

class FilesystemManager: ObservableObject {

    let manager = FileManager.default
    var documentsDirectory: String?

    @Published var files: [any FilesystemObject] = []
    @Published var extractionProgress: Progress?

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
                if directoryOrFileExists(at: subPath == "" ? documentsDirectoryURL.path() : subPath) {
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
                                var file = FSFile(name: url.deletingPathExtension().lastPathComponent,
                                                  extension: url.pathExtension.lowercased(),
                                                  path: url.path,
                                                  type: .notSet)
                                switch fileExtension {
                                case "mp3", "m4a", "wav", "alac":
                                    file.type = .audio
                                    return file
                                case "png", "jpg", "jpeg", "tif", "tiff":
                                    file.type = .image
                                    return file
                                case "txt":
                                    file.type = .text
                                    return file
                                case "pdf":
                                    file.type = .pdf
                                    return file
                                case "zip":
                                    file.type = .zip
                                    return file
                                default: break
                                }
                            }
                            return nil
                        }
                }
            }
        } catch {
            debugPrint(error.localizedDescription)
        }
        return []
    }

    func createDirectory(at directoryPath: String) {
        if !directoryOrFileExists(at: directoryPath) {
            do {
                try FileManager.default.createDirectory(atPath: directoryPath,
                                                        withIntermediateDirectories: true,
                                                        attributes: nil)
            } catch {
                debugPrint("Error occurred while creating directory: \(error.localizedDescription)")
            }
        }
    }

    func directoryOrFileExists(at directoryPath: String) -> Bool {
        return FileManager.default.fileExists(atPath: directoryPath)
    }

    func rename(file: FSFile, newName: String) {
        do {
            try manager
                .moveItem(atPath: file.path,
                          toPath: "\(file.containingFolderPath())\(newName).\(file.extension)")
        } catch {
            debugPrint("Error occurred while renaming file: \(error.localizedDescription)")
        }
    }

    func rename(directory: FSDirectory, newName: String) {
        do {
            try manager
                .moveItem(atPath: directory.path,
                          toPath: "\(directory.containingFolderPath())\(newName)/")
        } catch {
            debugPrint("Error occurred while renaming directory: \(error.localizedDescription)")
        }
    }

    func extractFiles(file: FSFile,
                      encoding: String.Encoding = .shiftJIS,
                      onProgressUpdate: @escaping () -> Void,
                      onError: @escaping (String) -> Void,
                      onCompletion: @escaping () -> Void) {
        let destinationURL = URL(filePath: file.path).deletingPathExtension()
        let destinationDirectory = destinationURL.path().removingPercentEncoding ?? destinationURL.path()
        debugPrint("Attempting to create directory \(destinationDirectory)...")
        createDirectory(at: destinationDirectory)
        debugPrint("Attempting to extract ZIP to \(destinationDirectory)...")
        extractionProgress = Progress()
        DispatchQueue.global(qos: .background).async {
            let observation = self.extractionProgress?.observe(\.fractionCompleted) { _, _ in
                DispatchQueue.main.async {
                    onProgressUpdate()
                }
            }
            do {
                try FileManager().unzipItem(at: URL(filePath: file.path),
                                            to: URL(filePath: destinationDirectory),
                                            skipCRC32: true,
                                            progress: self.extractionProgress,
                                            preferredEncoding: encoding)
                DispatchQueue.main.async {
                    onCompletion()
                }
            } catch {
                if !(self.extractionProgress?.isCancelled ?? false) {
                    debugPrint("Error occurred while extracting ZIP: \(error.localizedDescription)")
                    if encoding == .shiftJIS {
                        debugPrint("Attempting extraction with UTF-8...")
                        self.extractFiles(file: file,
                                          encoding: .utf8,
                                          onProgressUpdate: onProgressUpdate,
                                          onError: onError,
                                          onCompletion: onCompletion)
                    } else {
                        DispatchQueue.main.async {
                            onError(error.localizedDescription)
                        }
                    }
                } else {
                    debugPrint("ZIP extraction cancelled!")
                }
            }
            observation?.invalidate()
        }
    }

    func delete(_ file: any FilesystemObject) {
        do {
            try manager.removeItem(atPath: file.path)
        } catch {
            debugPrint("Error occurred while deleting file: \(error.localizedDescription)")
        }
    }
}
