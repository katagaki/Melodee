//
//  AudioConversionFormat.swift
//  Melodee
//
//  Created by GitHub Copilot on 2025/10/31.
//

import Foundation

enum AudioConversionFormat {
    case mp3_320kbps
    case wav
    case m4a_128kbps
    
    func fileExtension() -> String {
        switch self {
        case .mp3_320kbps: return "mp3"
        case .wav: return "wav"
        case .m4a_128kbps: return "m4a"
        }
    }
    
    func displayName() -> String {
        switch self {
        case .mp3_320kbps: return "MP3 320kbps"
        case .wav: return "WAV"
        case .m4a_128kbps: return "M4A 128kbps"
        }
    }
}
