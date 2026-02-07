//
//  AudioFile.swift
//  Melodee
//
//  Created by Claude on 2026/02/07.
//

import Foundation
import SwiftTagger
import UIKit

extension AudioFile {

    static func newTag(for file: FSFile) -> AudioFile? {
        debugPrint("Attempting to create new tag...")
        do {
            let fileURL = URL(fileURLWithPath: file.path)
            var audioFile = try AudioFile(location: fileURL)
            audioFile.title = ""
            try audioFile.write(outputLocation: fileURL)
            return audioFile
        } catch {
            debugPrint("Error occurred while initializing tag: \n\(error.localizedDescription)")
        }
        return nil
    }

    mutating func initializeTag(for file: FSFile) {
        debugPrint("Attempting to initialize tag...")
        do {
            let fileURL = URL(fileURLWithPath: file.path)
            self.title = ""
            try self.write(outputLocation: fileURL)
        } catch {
            debugPrint("Error occurred while initializing tag: \n\(error.localizedDescription)")
        }
    }

    // swiftlint:disable cyclomatic_complexity function_body_length
    mutating func saveTagData(to file: FSFile, tagData: Tag, retriesWhenFailed willRetry: Bool = true) -> Bool {
        debugPrint("Attempting to save tag data...")
        do {
            // Build title
            if let value = tagData.title {
                self.title = replaceTokens(value, file: file)
            }
            // Build artist
            if let value = tagData.artist {
                self.artist = replaceTokens(value, file: file)
            }
            // Build album
            if let value = tagData.album {
                self.album = replaceTokens(value, file: file)
            }
            // Build album artist
            if let value = tagData.albumArtist {
                self.albumArtist = replaceTokens(value, file: file)
            }
            // Build year via recordingDateTime
            if let value = tagData.year, let year = Int(value) {
                let calendar = Calendar(identifier: .iso8601)
                var components = DateComponents()
                components.year = year
                components.month = 1
                components.day = 1
                if let date = calendar.date(from: components) {
                    self.recordingDateTime = date
                }
            }
            // Build track
            if let value = tagData.track, value != "", let track = Int(value) {
                var currentTrack = self.trackNumber
                currentTrack.index = track
                self.trackNumber = currentTrack
            }
            // Build genre
            if let value = tagData.genre {
                self.genreCustom = value
            }
            // Build composer
            if let value = tagData.composer {
                self.composer = replaceTokens(value, file: file)
            }
            // Build disc number
            if let value = tagData.discNumber, let disc = Int(value) {
                var currentDisc = self.discNumber
                currentDisc.index = disc
                self.discNumber = currentDisc
            }
            // Build album art - use setCoverArt method
            if let data = tagData.albumArt {
                // Write temp file and use setCoverArt
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".jpg")
                try data.write(to: tempURL)
                try self.setCoverArt(imageLocation: tempURL)
                try? FileManager.default.removeItem(at: tempURL)
            }

            let outputURL = URL(fileURLWithPath: file.path)
            try self.write(outputLocation: outputURL)
            return true
        } catch {
            debugPrint("Error occurred while saving tag: \n\(error.localizedDescription)")
            if willRetry {
                initializeTag(for: file)
                return saveTagData(to: file, tagData: tagData, retriesWhenFailed: false)
            } else {
                return false
            }
        }
    }
    // swiftlint:enable cyclomatic_complexity function_body_length

    func replaceTokens(_ original: String, file: FSFile) -> String {
        var newString = original
        // Prepare tokens
        let componentsDash = file.name.components(separatedBy: "-").map { string in
            string.trimmingCharacters(in: .whitespaces)
        }
        let componentsDot = file.name.components(separatedBy: ".").map { string in
            string.trimmingCharacters(in: .whitespaces)
        }
        var trackNumber = ""
        if let properDigits = Bundle.main.plist(named: "ProperDigit"),
           let trackNumberDigits = getTrackNumber(file.name) {
            trackNumberDigits.forEach { character in
                if let digit = properDigits[String(character)] {
                    trackNumber += digit
                } else if character.isNumber {
                    trackNumber += String(character)
                }
            }
        }
        // Replace tokens
        let tokens: [String: String] = [
            "fileName": file.name,
            "folderName": file.containingFolderName(),
            "dashFront": componentsDash[0],
            "dashBack": componentsDash.count >= 2 ? componentsDash[1] : "",
            "dotFront": componentsDot[0],
            "dotBack": componentsDot.count >= 2 ? componentsDot[1] : "",
            "trackNumber": trackNumber
        ]
        for (key, value) in tokens {
            newString = newString.replacingOccurrences(of: "%\(key)%", with: value, options: .caseInsensitive)
        }
        return newString
    }

    func getTrackNumber(_ fileName: String) -> String? {
        if let trackNumberRegex = try? NSRegularExpression(pattern:
    """
    【?([１２３４５６７８９０]*)([⒈⒉⒊⒋⒌⒍⒎⒏⒐⒑]*)([①②③④⑤⑥⑦⑧⑨⑩]*)([0-9]*)】?(.*)
    """) {
            let stringRange = NSRange(fileName.startIndex..<fileName.endIndex, in: fileName)
            for match in trackNumberRegex.matches(in: fileName, options: [], range: stringRange) {
                for rangeIndex in 0..<match.numberOfRanges {
                    let matchRange = match.range(at: rangeIndex)
                    if matchRange == stringRange { continue }
                    if let substringRange = Range(matchRange, in: fileName) {
                        let capture = String(fileName[substringRange])
                        if capture != "" {
                            return capture
                        }
                    }
                }
            }
        }
        return nil
    }

}
