//
//  AudioFile.swift
//  Melodee
//
//  Created by Claude on 2026/02/07.
//

import Foundation
import SFBAudioEngine
import UIKit

extension AudioFile {

    /// Opens a file for reading metadata via SFBAudioEngine. Returns nil on failure.
    static func read(for file: FSFile) -> AudioFile? {
        do {
            let fileURL = URL(fileURLWithPath: file.path)
            return try AudioFile(readingPropertiesAndMetadataFrom: fileURL)
        } catch {
            debugPrint("Failed to read audio file \(file.name): \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Convenience accessors over metadata

    var title: String? { metadata.title }
    var artist: String? { metadata.artist }
    var albumTitle: String? { metadata.albumTitle }
    var albumArtist: String? { metadata.albumArtist }
    var genre: String? { metadata.genre }
    var composer: String? { metadata.composer }
    var trackNumber: Int? { metadata.trackNumber }
    var discNumber: Int? { metadata.discNumber }

    /// Integer year parsed from the tag's release date string (best-effort: first 4 digits).
    var year: Int? {
        guard let releaseDate = metadata.releaseDate else { return nil }
        let digits = releaseDate.prefix(4)
        return Int(digits)
    }

    /// Cover art as a UIImage, if any attached picture is present.
    var coverImage: UIImage? {
        guard let data = coverArtData else { return nil }
        return UIImage(data: data)
    }

    /// Cover art as raw image data (whatever bytes the tag contained — typically JPEG or PNG).
    var coverArtData: Data? {
        if let picture = metadata.attachedPictures(ofType: .frontCover).first
            ?? metadata.attachedPictures.first {
            return picture.imageData
        }
        return nil
    }

    // MARK: - Saving

    // swiftlint:disable cyclomatic_complexity function_body_length
    /// Writes the UI-layer `Tag` struct onto this file's metadata and saves to disk.
    func saveTagData(to file: FSFile, tagData: Tag) -> Bool {
        debugPrint("Attempting to save tag data...")
        do {
            if let value = tagData.title {
                metadata.title = replaceTokens(value, file: file)
            }
            if let value = tagData.artist {
                metadata.artist = replaceTokens(value, file: file)
            }
            if let value = tagData.album {
                metadata.albumTitle = replaceTokens(value, file: file)
            }
            if let value = tagData.albumArtist {
                metadata.albumArtist = replaceTokens(value, file: file)
            }
            if let value = tagData.year, !value.isEmpty {
                metadata.releaseDate = value
            }
            if let value = tagData.track, !value.isEmpty, let track = Int(value) {
                metadata.trackNumber = track
            }
            if let value = tagData.genre {
                metadata.genre = value
            }
            if let value = tagData.composer {
                metadata.composer = replaceTokens(value, file: file)
            }
            if let value = tagData.discNumber {
                if value.isEmpty {
                    metadata.discNumber = nil
                } else if let disc = Int(value) {
                    metadata.discNumber = disc
                }
            }
            if let data = tagData.albumArt {
                metadata.removeAttachedPictures(ofType: .frontCover)
                let picture = AttachedPicture(imageData: data, type: .frontCover)
                metadata.attachPicture(picture)
            } else if tagData.shouldRemoveAlbumArt {
                metadata.removeAllAttachedPictures()
            }
            try writeMetadata()
            return true
        } catch {
            debugPrint("Error occurred while saving tag: \(error.localizedDescription)")
            return false
        }
    }
    // swiftlint:enable cyclomatic_complexity function_body_length

    // MARK: - Token substitution (unchanged)

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
