//
//  TagTyped.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2023/09/12.
//

import AVFoundation
import Foundation
import SwiftTagger

struct TagTyped {

    var albumArt: Data?
    var title, artist, album, albumArtist, genre, composer: String?
    var year, track, discNumber: Int?

    init() {

    }

    init(_ file: FSFile, audioFile: AudioFile) async {
        title = audioFile.title ?? ""
        artist = audioFile.artist ?? ""
        album = audioFile.album ?? ""
        albumArtist = audioFile.albumArtist ?? ""
        year = audioFile.year
        track = audioFile.trackNumber.index != 0 ? audioFile.trackNumber.index : nil
        genre = audioFile.genreCustom ?? ""
        composer = audioFile.composer ?? ""
        discNumber = audioFile.discNumber.index != 0 ? audioFile.discNumber.index : nil

        if let coverArtImage = audioFile.coverArt {
            albumArt = coverArtImage.pngData() ?? coverArtImage.jpegData(compressionQuality: 1.0)
        } else {
            albumArt = await albumArtUsingAVPlayer(file: file)
        }
    }

    // swiftlint:disable cyclomatic_complexity function_body_length
    mutating func merge(with file: FSFile, audioFile: AudioFile) async {
        if title != audioFile.title ?? "" {
            title = nil
        }
        if artist != audioFile.artist ?? "" {
            artist = nil
        }
        if album != audioFile.album ?? "" {
            album = nil
        }
        if albumArtist != audioFile.albumArtist ?? "" {
            albumArtist = nil
        }
        if let yearFromTag = audioFile.year, year != yearFromTag {
            year = nil
        } else if audioFile.year == nil && year != nil {
            year = nil
        }
        let trackFromTag = audioFile.trackNumber.index != 0 ? audioFile.trackNumber.index : nil
        if let trackValue = trackFromTag, track != trackValue {
            track = nil
        } else if trackFromTag == nil && track != nil {
            track = nil
        }
        if genre != audioFile.genreCustom ?? "" {
            genre = nil
        }
        if composer != audioFile.composer ?? "" {
            composer = nil
        }
        let discNumberFromTag = audioFile.discNumber.index != 0 ? audioFile.discNumber.index : nil
        if let discValue = discNumberFromTag,
           discNumber != discValue {
            discNumber = nil
        } else if discNumberFromTag == nil && discNumber != nil {
            discNumber = nil
        }
        if let coverArtImage = audioFile.coverArt,
           let albumArtFromTag = coverArtImage.pngData() ?? coverArtImage.jpegData(compressionQuality: 1.0) {
            if albumArt != albumArtFromTag {
                albumArt = nil
            }
        } else if let albumArtFromTag = await albumArtUsingAVPlayer(file: file) {
            if albumArt != albumArtFromTag {
                albumArt = nil
            }
        } else {
            if albumArt != nil {
                albumArt = nil
            }
        }
    }
    // swiftlint:enable cyclomatic_complexity function_body_length

    func albumArtUsingAVPlayer(file: FSFile) async -> Data? {
        do {
            let playerItem = AVPlayerItem(url: URL(filePath: file.path))
            let metadataList = try await playerItem.asset.load(.metadata)
            for item in metadataList {
                switch item.commonKey {
                case .commonKeyArtwork?:
                    if let data = try await item.load(.dataValue) {
                        return data
                    }
                default: break
                }
            }
        } catch {
            debugPrint(error.localizedDescription)
        }
        return nil
    }
}
