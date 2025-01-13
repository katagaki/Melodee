//
//  ID3Tag.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2023/09/15.
//

import Foundation
import ID3TagEditor
import UIKit

extension ID3Tag {

    static func newTag(for file: FSFile) -> ID3Tag? {
        debugPrint("Attempting to create new tag...")
        do {
            let id3Tag = ID32v3TagBuilder()
                .title(frame: ID3FrameWithStringContent(content: ""))
                .build()
            try ID3TagEditor().write(tag: id3Tag, to: file.path)
            return id3Tag
        } catch {
            debugPrint("Error occurred while initializing tag: \n\(error.localizedDescription)")
        }
        return nil
    }

    func initializeTag(for file: FSFile) {
        debugPrint("Attempting to initialize tag...")
        do {
            let id3Tag = ID32v3TagBuilder()
                .title(frame: ID3FrameWithStringContent(content: ""))
                .build()
            try ID3TagEditor().write(tag: id3Tag, to: file.path)
        } catch {
            debugPrint("Error occurred while initializing tag: \n\(error.localizedDescription)")
        }
    }

    // swiftlint:disable cyclomatic_complexity function_body_length
    func saveTagData(to file: FSFile, tagData: Tag, retriesWhenFailed willRetry: Bool = true) -> Bool {
        debugPrint("Attempting to save tag data...")
        do {
            var tagBuilder = ID32v3TagBuilder()
            // Build title frame
            if let frame = id3Frame(tagData.title, returns: ID3FrameWithStringContent.self, referencing: file) {
                tagBuilder = tagBuilder.title(frame: frame)
            } else if let value = ID3TagContentReader(id3Tag: self).title() {
                tagBuilder = tagBuilder.title(frame: id3Frame(value, referencing: file))
            }
            // Build artist frame
            if let frame = id3Frame(tagData.artist, returns: ID3FrameWithStringContent.self, referencing: file) {
                tagBuilder = tagBuilder.artist(frame: frame)
            } else if let value = ID3TagContentReader(id3Tag: self).artist() {
                tagBuilder = tagBuilder.artist(frame: id3Frame(value, referencing: file))
            }
            // Build album frame
            if let frame = id3Frame(tagData.album, returns: ID3FrameWithStringContent.self, referencing: file) {
                tagBuilder = tagBuilder.album(frame: frame)
            } else if let value = ID3TagContentReader(id3Tag: self).album() {
                tagBuilder = tagBuilder.album(frame: id3Frame(value, referencing: file))
            }
            // Build album artist frame
            if let frame = id3Frame(tagData.albumArtist, returns: ID3FrameWithStringContent.self, referencing: file) {
                tagBuilder = tagBuilder.albumArtist(frame: frame)
            } else if let value = ID3TagContentReader(id3Tag: self).albumArtist() {
                tagBuilder = tagBuilder.albumArtist(frame: id3Frame(value, referencing: file))
            }
            // Build year frame
            if let frame = id3Frame(tagData.year, returns: ID3FrameWithIntegerContent.self) {
                tagBuilder = tagBuilder.recordingYear(frame: frame)
            } else if let value = ID3TagContentReader(id3Tag: self).recordingYear() {
                tagBuilder = tagBuilder.recordingYear(frame: ID3FrameWithIntegerContent(value: value))
            }
            // Build track frame
            if let frame = id3Frame(tagData.track, returns: ID3FramePartOfTotal.self, referencing: file),
                frame.part != -999999 {
                tagBuilder = tagBuilder.trackPosition(frame: frame)
            } else if tagData.track == nil, let value = ID3TagContentReader(id3Tag: self).trackPosition() {
                tagBuilder = tagBuilder.trackPosition(frame: id3Frame(value.position, total: value.total))
            }
            // Build genre frame
            if let frame = id3Frame(tagData.genre, returns: ID3FrameGenre.self) {
                tagBuilder = tagBuilder.genre(frame: frame)
            } else if let value = ID3TagContentReader(id3Tag: self).genre(),
                      let description = value.description {
                tagBuilder = tagBuilder.genre(frame: id3Frame(description, identifier: value.identifier))
            }
            // Build composer frame
            if let frame = id3Frame(tagData.composer, returns: ID3FrameWithStringContent.self, referencing: file) {
                tagBuilder = tagBuilder.composer(frame: frame)
            } else if let value = ID3TagContentReader(id3Tag: self).composer() {
                tagBuilder = tagBuilder.composer(frame: id3Frame(value, referencing: file))
            }
            // Build disc number frame
            if let frame = id3Frame(tagData.discNumber, returns: ID3FramePartOfTotal.self) {
                tagBuilder = tagBuilder.discPosition(frame: frame)
            } else if let value = ID3TagContentReader(id3Tag: self).discPosition() {
                tagBuilder = tagBuilder.discPosition(frame: id3Frame(value.position, total: value.total))
            }
            // Build album art frame
            if let frame = id3Frame(tagData.albumArt, type: .frontCover) {
                tagBuilder = tagBuilder.attachedPicture(pictureType: .frontCover, frame: frame)
            } else if let albumArt = ID3TagContentReader(id3Tag: self).attachedPictures()
                .first(where: { $0.type == .frontCover }),
                      let frame = id3Frame(albumArt.picture, type: .frontCover) {
                tagBuilder = tagBuilder
                    .attachedPicture(pictureType: .frontCover, frame: frame)
            }
            try ID3TagEditor().write(tag: tagBuilder.build(), to: file.path)
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

    // swiftlint:disable cyclomatic_complexity
    func id3Frame<T>(_ value: String?,
                     returns type: T.Type,
                     referencing file: FSFile? = nil) -> T? {
        switch type {
        case is ID3FrameWithStringContent.Type:
            if let value {
                if let file = file {
                    return ID3FrameWithStringContent(content: replaceTokens(value, file: file)) as? T
                } else {
                    return ID3FrameWithStringContent(content: value) as? T
                }
            }
        case is ID3FrameWithIntegerContent.Type:
            if let value {
                if let int = Int(value) {
                    return ID3FrameWithIntegerContent(value: int) as? T
                } else {
                    return ID3FrameWithIntegerContent(value: nil) as? T
                }
            }
        case is ID3FramePartOfTotal.Type:
            if let value {
                if value != "", let int = Int(value) {
                    return ID3FramePartOfTotal(part: int, total: nil) as? T
                } else {
                    return ID3FramePartOfTotal(part: -999999, total: nil) as? T
                }
            }
        case is ID3FrameGenre.Type:
            if let value {
                return ID3FrameGenre(genre: nil, description: value) as? T
            }
        default: break
        }
        return nil
    }
    // swiftlint:enable cyclomatic_complexity

    func id3Frame(_ value: String,
                  referencing file: FSFile?) -> ID3FrameWithStringContent {
        if let file = file {
            return ID3FrameWithStringContent(content: replaceTokens(value, file: file))
        } else {
            return ID3FrameWithStringContent(content: value)
        }
    }

    func id3Frame(_ value: Int, total: Int?) -> ID3FramePartOfTotal {
        return ID3FramePartOfTotal(part: value, total: total)
    }

    func id3Frame(_ value: String, identifier: ID3Genre?) -> ID3FrameGenre {
        return ID3FrameGenre(genre: identifier, description: value)
    }

    func id3Frame(_ data: Data?, type: ID3PictureType) -> ID3FrameAttachedPicture? {
        if let data = data,
           let image = UIImage(data: data) {
            if let pngData = image.pngData() {
                return ID3FrameAttachedPicture(picture: pngData,
                                               type: type,
                                               format: .png)
            } else if let jpgData = image.jpegData(compressionQuality: 1.0) {
                return ID3FrameAttachedPicture(picture: jpgData,
                                               type: type,
                                               format: .jpeg)
            }
        }
        return nil
    }

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
