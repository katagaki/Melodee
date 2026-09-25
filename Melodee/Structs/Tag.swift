import Foundation

struct Tag {

    var albumArt: Data?
    var shouldRemoveAlbumArt: Bool = false
    var title: String?
    var artist: String?
    var album: String?
    var albumArtist: String?
    var year: String?
    var track: String?
    var genre: String?
    var composer: String?
    var discNumber: String?

    init() { }

    init(from tagCombined: TagTyped) {
        albumArt = tagCombined.albumArt
        title = tagCombined.title
        artist = tagCombined.artist
        album = tagCombined.album
        albumArtist = tagCombined.albumArtist
        year = tagCombined.year
        if let track = tagCombined.track {
            self.track = String(track)
        }
        genre = tagCombined.genre
        composer = tagCombined.composer
        if let discNumber = tagCombined.discNumber {
            self.discNumber = String(discNumber)
        }
    }

    var hasValidNumbers: Bool {
        let trackIsValid = track.map {
            $0.isEmpty || $0.uppercased() == "%TRACKNUMBER%" || Self.isWholeNumber($0)
        } ?? true
        let discIsValid = discNumber.map {
            $0.isEmpty || Self.isWholeNumber($0)
        } ?? true
        return trackIsValid && discIsValid
    }

    static func isWholeNumber(_ value: String) -> Bool {
        !value.isEmpty && value.allSatisfy { $0.isASCII && $0.isNumber } && Int(value) != nil
    }
}
