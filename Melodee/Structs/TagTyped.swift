//
//  TagTyped.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2023/09/12.
//

@preconcurrency import AVFoundation
import Foundation
import SFBAudioEngine

struct TagTyped {

    var albumArt: Data?
    var title, artist, album, albumArtist, genre, composer: String?
    var year, track, discNumber: Int?

    init() {

    }

    init(_ file: FSFile, audioFile: AudioFile) async {
        title = audioFile.title ?? ""
        artist = audioFile.artist ?? ""
        album = audioFile.albumTitle ?? ""
        albumArtist = audioFile.albumArtist ?? ""
        year = audioFile.year
        track = audioFile.trackNumber
        genre = audioFile.genre ?? ""
        composer = audioFile.composer ?? ""
        discNumber = audioFile.discNumber

        if let data = audioFile.coverArtData {
            albumArt = data
        } else {
            albumArt = await albumArtUsingAVPlayer(file: file)
        }
    }

    // swiftlint:disable cyclomatic_complexity
    mutating func merge(with file: FSFile, audioFile: AudioFile) async {
        if title != audioFile.title ?? "" {
            title = nil
        }
        if artist != audioFile.artist ?? "" {
            artist = nil
        }
        if album != audioFile.albumTitle ?? "" {
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
        if let trackValue = audioFile.trackNumber, track != trackValue {
            track = nil
        } else if audioFile.trackNumber == nil && track != nil {
            track = nil
        }
        if genre != audioFile.genre ?? "" {
            genre = nil
        }
        if composer != audioFile.composer ?? "" {
            composer = nil
        }
        if let discValue = audioFile.discNumber, discNumber != discValue {
            discNumber = nil
        } else if audioFile.discNumber == nil && discNumber != nil {
            discNumber = nil
        }
        if let albumArtFromTag = audioFile.coverArtData {
            if albumArt != albumArtFromTag {
                albumArt = nil
            }
        } else if let albumArtFromTag = await albumArtUsingAVPlayer(file: file) {
            if albumArt != albumArtFromTag {
                albumArt = nil
            }
        } else if albumArt != nil {
            albumArt = nil
        }
    }
    // swiftlint:enable cyclomatic_complexity

    /// Fallback album-art source for containers where SFBAudioEngine couldn't surface an attached picture.
    func albumArtUsingAVPlayer(file: FSFile) async -> Data? {
        do {
            let asset = AVURLAsset(url: URL(filePath: file.path))
            let metadataList = try await asset.load(.metadata)
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
