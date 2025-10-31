//
//  AudioConversionFormat.swift
//  Melodee
//
//  Created by GitHub Copilot on 2025/10/31.
//

import Foundation

enum AudioConversionFormat {
    case m4a_high_quality
    case wav
    case m4a_128kbps
    
    func fileExtension() -> String {
        switch self {
        case .m4a_high_quality: return "m4a"
        case .wav: return "wav"
        case .m4a_128kbps: return "m4a"
        }
    }
    
    func displayName() -> String {
        switch self {
        case .m4a_high_quality: return "M4A High Quality"
        case .wav: return "WAV"
        case .m4a_128kbps: return "M4A 128kbps"
        }
    }
}
