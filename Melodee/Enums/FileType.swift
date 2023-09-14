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
    case notSet

    func icon() -> Image {
        switch self {
        case .audio: return Image("File.Audio")
        case .image: return Image("File.Image")
        case .zip: return Image("File.Archive")
        default: return Image("File.Generic")
        }
    }
}
