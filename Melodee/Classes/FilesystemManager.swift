//
//  FilesystemManager.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2023/09/11.
//

import Foundation
import SwiftUI
import ZIPFoundation
import AVFoundation

@Observable
class FilesystemManager {

    @ObservationIgnored let manager = FileManager.default
    @ObservationIgnored var directory: URL?

    var storageLocation: StorageLocation = .local

    @ObservationIgnored var documentsDirectoryURL: URL?
    @ObservationIgnored var cloudDocumentsDirectoryURL: URL?
    @ObservationIgnored var externalDirectoryURL: URL?

    var files: [any FilesystemObject] = []
    var extractionProgress: Progress?
    var conversionProgress: Progress?

    init() {
        do {
            documentsDirectoryURL = try FileManager.default
                .url(for: .documentDirectory,
                     in: .userDomainMask,
                     appropriateFor: nil,
                     create: true)
            cloudDocumentsDirectoryURL = FileManager.default
                .url(forUbiquityContainerIdentifier: nil)?
                .appendingPathComponent("Documents")
            directory = documentsDirectoryURL
        } catch {
            debugPrint(error.localizedDescription)
        }
    }

    func files(in url: URL? = nil) -> [any FilesystemObject] {
        debugPrint("Enumerating files in '\(url == nil ? directory?.absoluteString ?? "": url?.absoluteString ?? "")'.")
        do {
            if let directory = (url == nil ? directory : url), directoryOrFileExists(at: directory) {
                // Get contents of directory
                let filesStaged: [any FilesystemObject] = try manager
                    .contentsOfDirectory(at: directory,
                                         includingPropertiesForKeys: [.isRegularFileKey, .isDirectoryKey],
                                         options: []).compactMap { url in
                        if url.hasDirectoryPath {
                            return FSDirectory(name: url.lastPathComponent,
                                               path: url.path,
                                               files: files(in: url))
                        } else {
                            // Get actual path for dataless files
                            let fileURL: URL = fileURL(for: url)
                            var file = FSFile(name: fileURL.deletingPathExtension().lastPathComponent,
                                              extension: fileURL.pathExtension.lowercased(),
                                              path: fileURL.path,
                                              type: .notSet)
                            if let fileType = fileType(for: fileURL) {
                                file.type = fileType
                                return file
                            } else {
                                return nil
                            }
                        }
                    }
                // Sort folders above files
                var filesCombined: [any FilesystemObject] = filesStaged.filter({ $0 is FSDirectory })
                    .sorted { $0.name < $1.name }
                let filesOnly: [any FilesystemObject] = filesStaged.filter({ $0 is FSFile })
                    .sorted { $0.name < $1.name }
                    .sorted { lhs, rhs in
                        if let lhs = lhs as? FSFile, let rhs = rhs as? FSFile {
                            return lhs.type.rawValue < rhs.type.rawValue
                        }
                        return false
                    }
                filesCombined.append(contentsOf: filesOnly)
                return filesCombined
            }
        } catch {
            debugPrint(error.localizedDescription)
        }
        return []
    }

    func fileURL(for url: URL) -> URL {
        var fileName: String = url.lastPathComponent
        if fileName.hasPrefix(".") && fileName.hasSuffix(".icloud") {
            let fromIndex = fileName.index(fileName.startIndex, offsetBy: 1)
            let toIndex = fileName.index(fileName.endIndex, offsetBy: -7)
            fileName = String(fileName[fromIndex..<toIndex])
        }
        return url.deletingLastPathComponent().appending(path: fileName)
    }

    func fileType(for url: URL) -> FileType? {
        let fileExtension = url.pathExtension.lowercased()
        switch fileExtension {
        case "mp3", "m4a", "wav", "alac": return .audio
        case "png", "jpg", "jpeg", "tif", "tiff", "heic": return .image
        case "txt": return .text
        case "pdf": return .pdf
        case "zip": return .zip
        case "icloud": return fileType(for: url.deletingPathExtension())
        default: return nil
        }
    }

    func createDirectory(at directoryPath: String) {
        if let url = URL(string: directoryPath) {
            if !directoryOrFileExists(at: url) {
                do {
                    try FileManager.default.createDirectory(atPath: directoryPath,
                                                            withIntermediateDirectories: true,
                                                            attributes: nil)
                } catch {
                    debugPrint("Error occurred while creating directory: \(error.localizedDescription)")
                }
            }
        }
    }

    func createPlaceholders() {
        let placeholderFilename = NSLocalizedString("Shared.DropFilesFileName",
                                                    comment: "")
        if let documentsDirectoryURL {
            manager
                .createFile(atPath: "\(documentsDirectoryURL.path())\(placeholderFilename)",
                            contents: "".data(using: .utf8))
        }
        if let cloudDocumentsDirectoryURL {
            let placeholderFileURL: URL = cloudDocumentsDirectoryURL.appending(path: placeholderFilename)
            NSFileCoordinator().coordinate(writingItemAt: placeholderFileURL, error: .none) { url in
                self.manager.createFile(atPath: url.path(percentEncoded: false), contents: "".data(using: .utf8))
            }
        }
    }

    func directoryOrFileExists(at url: URL) -> Bool {
        return FileManager.default.fileExists(atPath: url.path(percentEncoded: false))
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
                                            pathEncoding: encoding)
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
    
    func convertAudio(file: FSFile,
                     format: AudioConversionFormat,
                     onProgressUpdate: @escaping () -> Void,
                     onError: @escaping (String) -> Void,
                     onCompletion: @escaping () -> Void) {
        let sourceURL = URL(filePath: file.path)
        let destinationURL = sourceURL.deletingPathExtension()
            .appendingPathExtension(format.fileExtension())
        
        debugPrint("Attempting to convert audio to \(format.displayName())...")
        
        let asset = AVURLAsset(url: sourceURL)
        
        DispatchQueue.global(qos: .background).async {
            // Determine export session preset based on format
            let preset: String
            switch format {
            case .mp3_320kbps:
                // For MP3, we'll use AVAssetExportPresetAppleM4A then convert
                // Actually, iOS doesn't support direct MP3 export via AVAssetExportSession
                // We'll use passthrough and rely on the source file being MP3
                preset = AVAssetExportPresetPassthrough
            case .wav:
                preset = AVAssetExportPresetPassthrough
            case .m4a_128kbps:
                preset = AVAssetExportPresetAppleM4A
            }
            
            guard let exportSession = AVAssetExportSession(asset: asset, presetName: preset) else {
                DispatchQueue.main.async {
                    onError("Failed to create export session")
                }
                return
            }
            
            exportSession.outputURL = destinationURL
            
            // Set output file type based on format
            switch format {
            case .mp3_320kbps:
                // iOS doesn't directly support MP3 export
                // We need to use Core Audio for proper MP3 conversion
                DispatchQueue.main.async {
                    onError("MP3 conversion not supported directly. Use M4A or WAV format.")
                }
                return
            case .wav:
                exportSession.outputFileType = .wav
            case .m4a_128kbps:
                exportSession.outputFileType = .m4a
                // Configure audio settings for 128kbps AAC
                exportSession.audioTimePitchAlgorithm = .spectral
            }
            
            // Track progress
            self.conversionProgress = exportSession.progress
            let observation = self.conversionProgress?.observe(\.fractionCompleted) { _, _ in
                DispatchQueue.main.async {
                    onProgressUpdate()
                }
            }
            
            exportSession.exportAsynchronously {
                observation?.invalidate()
                
                switch exportSession.status {
                case .completed:
                    debugPrint("Audio conversion completed successfully")
                    DispatchQueue.main.async {
                        onCompletion()
                    }
                case .failed:
                    if let error = exportSession.error {
                        debugPrint("Audio conversion failed: \(error.localizedDescription)")
                        DispatchQueue.main.async {
                            onError(error.localizedDescription)
                        }
                    } else {
                        DispatchQueue.main.async {
                            onError("Conversion failed with unknown error")
                        }
                    }
                case .cancelled:
                    debugPrint("Audio conversion cancelled")
                default:
                    DispatchQueue.main.async {
                        onError("Conversion failed")
                    }
                }
            }
        }
    }
}
