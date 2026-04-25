//
//  AudioConverter.swift
//  Melodee
//
//  Created by Claude on 2026/02/07.
//

@preconcurrency import AVFoundation
import Foundation
import SFBAudioEngine

enum AudioConversionError: Error {
    case unsupportedConversion
    case fileAlreadyExists
}

class AudioConverter {

    /// Converts an audio file to a different format using SFBAudioEngine's converter.
    /// - Parameters:
    ///   - sourceFile: The source FSFile to convert.
    ///   - targetFormat: Target format extension ("mp3", "wav", "m4a").
    ///   - deleteOriginal: Whether to delete the original file after conversion.
    ///   - progressHandler: Optional handler called at start (0.0) and completion (1.0). SFB's
    ///     `AudioConverter.convert` is synchronous and does not surface incremental progress.
    /// - Returns: A new FSFile representing the converted file.
    static func convert(
        _ sourceFile: FSFile,
        to targetFormat: String,
        deleteOriginal: Bool = false,
        progressHandler: (@Sendable (Double) -> Void)? = nil
    ) async throws -> FSFile {
        let sourceURL = URL(fileURLWithPath: sourceFile.path)
        let outputURL = sourceURL.deletingPathExtension().appendingPathExtension(targetFormat)

        if FileManager.default.fileExists(atPath: outputURL.path) {
            throw AudioConversionError.fileAlreadyExists
        }
        guard isConversionSupported(from: sourceFile.extension, to: targetFormat) else {
            throw AudioConversionError.unsupportedConversion
        }

        progressHandler?(0.0)

        try await Task.detached(priority: .userInitiated) {
            let encoder = try makeEncoder(for: targetFormat, outputURL: outputURL)
            try SFBAudioEngine.AudioConverter.convert(fromURL: sourceURL, usingEncoder: encoder)
        }.value

        progressHandler?(1.0)

        if deleteOriginal {
            try FileManager.default.removeItem(at: sourceURL)
        }

        return FSFile(
            name: outputURL.deletingPathExtension().lastPathComponent,
            extension: targetFormat.lowercased(),
            path: outputURL.path,
            type: .audio
        )
    }

    /// Builds an SFB encoder configured for the requested target format with reasonable defaults.
    private static func makeEncoder(for targetFormat: String, outputURL: URL) throws -> AudioEncoder {
        switch targetFormat.lowercased() {
        case "mp3":
            let encoder = try AudioEncoder(url: outputURL, encoderName: .mp3)
            encoder.settings = [
                AudioEncodingSettingsKey.mp3ConstantBitrate: NSNumber(value: 320),
                AudioEncodingSettingsKey.mp3Quality: NSNumber(value: 2)
            ]
            return encoder
        case "m4a":
            let encoder = try AudioEncoder(url: outputURL, encoderName: .coreAudio)
            encoder.settings = [
                AudioEncodingSettingsKey.coreAudioFileTypeID: NSNumber(value: kAudioFileM4AType),
                AudioEncodingSettingsKey.coreAudioFormatID: NSNumber(value: kAudioFormatMPEG4AAC)
            ]
            return encoder
        case "wav":
            let encoder = try AudioEncoder(url: outputURL, encoderName: .libsndfile)
            encoder.settings = [
                AudioEncodingSettingsKey.libsndfileMajorFormat: LibsndfileMajorFormat.WAV,
                AudioEncodingSettingsKey.libsndfileSubtype: LibsndfileSubtype.PCM_16
            ]
            return encoder
        default:
            throw AudioConversionError.unsupportedConversion
        }
    }

    /// Checks if a conversion between two formats is supported.
    static func isConversionSupported(from sourceFormat: String, to targetFormat: String) -> Bool {
        let source = sourceFormat.lowercased()
        let target = targetFormat.lowercased()
        if source == target { return false }
        return supportedConversions[source]?.contains(target) ?? false
    }

    /// Returns the available conversion targets for a given source format.
    static func availableFormats(for sourceFormat: String) -> [String] {
        return supportedConversions[sourceFormat.lowercased()] ?? []
    }

    /// Allowed source-to-target conversions. Lossy sources never target lossless.
    private static let supportedConversions: [String: [String]] = [
        "wav": ["m4a", "mp3"],
        "mp3": ["m4a"],
        "m4a": ["mp3"],
        "alac": ["m4a", "wav", "mp3"]
    ]
}
