//
//  FileType.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2023/09/12.
//

import Foundation
import SwiftUI

enum FileType: String, Codable {
    case audio
    case image
    case text
    case pdf
    case zip
    case playlist
    case notSet

    func icon() -> Image {
        switch self {
        case .audio: return Image("File.Audio")
        case .image: return Image("File.Image")
        case .pdf: return Image("File.PDF")
        case .zip: return Image("File.Archive")
        case .playlist: return Image(systemName: "music.note.list")
        default: return Image("File.Generic")
        }
    }
}
