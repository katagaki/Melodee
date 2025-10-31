//
//  AudioConversionFormat.swift
//  Melodee
//
//  Created by GitHub Copilot on 2025/10/31.
//

import Foundation

enum AudioConversionFormat {
    case m4a
    case wav
    
    func fileExtension() -> String {
        switch self {
        case .m4a: return "m4a"
        case .wav: return "wav"
        }
    }
    
    func displayName() -> String {
        switch self {
        case .m4a: return "M4A (AAC)"
        case .wav: return "WAV (Lossless)"
        }
    }
}
