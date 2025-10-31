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
        
        // Check if source and destination formats are the same
        if sourceURL.pathExtension.lowercased() == format.fileExtension() {
            DispatchQueue.main.async {
                onError("Source and destination formats are the same")
            }
            return
        }
        
        // Check if destination file already exists
        if FileManager.default.fileExists(atPath: destinationURL.path(percentEncoded: false)) {
            DispatchQueue.main.async {
                onError("Destination file already exists")
            }
            return
        }
        
        let asset = AVURLAsset(url: sourceURL)
        
        DispatchQueue.global(qos: .background).async {
            // For MP3 format, we'll use M4A with high quality AAC encoding
            // since iOS doesn't support MP3 encoding natively
            let actualFormat: AudioConversionFormat = format == .mp3_320kbps ? .m4a_128kbps : format
            let actualDestinationURL = format == .mp3_320kbps ? 
                sourceURL.deletingPathExtension().appendingPathExtension("m4a") : destinationURL
            
            // Determine export session preset based on format
            let preset: String
            switch actualFormat {
            case .wav:
                preset = AVAssetExportPresetPassthrough
            case .m4a_128kbps, .mp3_320kbps:
                preset = AVAssetExportPresetAppleM4A
            }
            
            guard let exportSession = AVAssetExportSession(asset: asset, presetName: preset) else {
                DispatchQueue.main.async {
                    onError("Failed to create export session")
                }
                return
            }
            
            exportSession.outputURL = actualDestinationURL
            
            // Set output file type based on format
            switch actualFormat {
            case .wav:
                exportSession.outputFileType = .wav
            case .m4a_128kbps, .mp3_320kbps:
                exportSession.outputFileType = .m4a
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
                    if format == .mp3_320kbps {
                        debugPrint("Note: Converted to M4A instead of MP3 due to iOS limitations")
                    }
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
                    // Clean up partial file if it exists
                    if FileManager.default.fileExists(atPath: actualDestinationURL.path(percentEncoded: false)) {
                        try? FileManager.default.removeItem(at: actualDestinationURL)
                    }
                default:
                    DispatchQueue.main.async {
                        onError("Conversion failed")
                    }
                }
            }
        }
    }
}
