//
//  AudioConverter.swift
//  Melodee
//
//  Created by Claude on 2026/02/07.
//

import AVFoundation
import Foundation

enum AudioConversionError: Error {
    case invalidInputFile
    case exportSessionFailed
    case unsupportedConversion
    case fileAlreadyExists
    case noAudioTrack
    case readerFailed
    case writerFailed
}

class AudioConverter {

    /// Converts an audio file from one format to another using AVAssetReader and AVAssetWriter
    /// - Parameters:
    ///   - sourceFile: The source FSFile to convert
    ///   - targetFormat: The target format extension (e.g., "mp3", "wav", "m4a")
    ///   - deleteOriginal: Whether to delete the original file after conversion
    ///   - progressHandler: Optional closure to track conversion progress
    /// - Returns: The newly created FSFile
    static func convert(
        _ sourceFile: FSFile,
        to targetFormat: String,
        deleteOriginal: Bool = false,
        progressHandler: ((Double) -> Void)? = nil
    ) async throws -> FSFile {
        let sourceURL = URL(fileURLWithPath: sourceFile.path)

        // Create output URL with new extension
        let outputURL = sourceURL.deletingPathExtension().appendingPathExtension(targetFormat)

        // Check if output file already exists
        if FileManager.default.fileExists(atPath: outputURL.path) {
            throw AudioConversionError.fileAlreadyExists
        }

        // For M4A output, use AVAssetExportSession (simpler and more reliable)
        if targetFormat.lowercased() == "m4a" {
            return try await convertUsingExportSession(
                sourceFile: sourceFile,
                sourceURL: sourceURL,
                outputURL: outputURL,
                targetFormat: targetFormat,
                deleteOriginal: deleteOriginal,
                progressHandler: progressHandler
            )
        }

        // For WAV output, use AVAssetReader/Writer for PCM conversion
        return try await convertUsingReaderWriter(
            sourceFile: sourceFile,
            sourceURL: sourceURL,
            outputURL: outputURL,
            targetFormat: targetFormat,
            deleteOriginal: deleteOriginal,
            progressHandler: progressHandler
        )
    }

    /// Converts audio using AVAssetExportSession (for M4A output)
    private static func convertUsingExportSession(
        sourceFile: FSFile,
        sourceURL: URL,
        outputURL: URL,
        targetFormat: String,
        deleteOriginal: Bool,
        progressHandler: ((Double) -> Void)?
    ) async throws -> FSFile {
        let asset = AVAsset(url: sourceURL)

        // Use AppleM4A preset for M4A output
        let preset = AVAssetExportPresetAppleM4A
        let outputFileType = AVFileType.m4a

        // Check compatibility
        let isCompatible = await AVAssetExportSession.compatibility(
            ofExportPreset: preset,
            with: asset,
            outputFileType: outputFileType
        )

        guard isCompatible else {
            throw AudioConversionError.unsupportedConversion
        }

        // Create export session
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: preset) else {
            throw AudioConversionError.exportSessionFailed
        }

        exportSession.outputFileType = outputFileType
        exportSession.outputURL = outputURL

        // Start progress monitoring if handler provided
        let progressTask: Task<Void, Never>? = if let progressHandler {
            Task {
                while !Task.isCancelled {
                    progressHandler(Double(exportSession.progress))
                    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                }
            }
        } else {
            nil
        }

        // Perform the export
        await exportSession.export()

        // Cancel progress monitoring
        progressTask?.cancel()

        // Check for errors
        if let error = exportSession.error {
            throw error
        }

        // Delete original if requested
        if deleteOriginal {
            try FileManager.default.removeItem(at: sourceURL)
        }

        // Create and return new FSFile
        let newFile = FSFile(
            name: outputURL.deletingPathExtension().lastPathComponent,
            extension: targetFormat.lowercased(),
            path: outputURL.path,
            type: .audio
        )

        return newFile
    }

    /// Converts audio using AVAssetReader and AVAssetWriter (for WAV output)
    private static func convertUsingReaderWriter(
        sourceFile: FSFile,
        sourceURL: URL,
        outputURL: URL,
        targetFormat: String,
        deleteOriginal: Bool,
        progressHandler: ((Double) -> Void)?
    ) async throws -> FSFile {
        let asset = AVAsset(url: sourceURL)

        // Get the audio track
        guard let audioTrack = try await asset.loadTracks(withMediaType: .audio).first else {
            throw AudioConversionError.noAudioTrack
        }

        // Create reader
        let reader = try AVAssetReader(asset: asset)

        // Configure reader output for PCM audio
        let readerOutputSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsNonInterleaved: false
        ]

        let readerOutput = AVAssetReaderTrackOutput(track: audioTrack, outputSettings: readerOutputSettings)
        reader.add(readerOutput)

        // Create writer
        let writer = try AVAssetWriter(outputURL: outputURL, fileType: .wav)

        // Configure writer input for WAV output
        let writerInput = AVAssetWriterInput(mediaType: .audio, outputSettings: nil)
        writer.add(writerInput)

        // Start reading and writing
        guard reader.startReading() else {
            throw AudioConversionError.readerFailed
        }

        guard writer.startWriting() else {
            throw AudioConversionError.writerFailed
        }

        writer.startSession(atSourceTime: .zero)

        // Get duration for progress calculation
        let duration = try await asset.load(.duration)
        let durationSeconds = CMTimeGetSeconds(duration)
        var processedSamples = 0

        // Process audio samples
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            writerInput.requestMediaDataWhenReady(on: DispatchQueue(label: "audioConversion")) {
                while writerInput.isReadyForMoreMediaData {
                    guard let sampleBuffer = readerOutput.copyNextSampleBuffer() else {
                        writerInput.markAsFinished()
                        writer.finishWriting {
                            continuation.resume()
                        }
                        return
                    }

                    writerInput.append(sampleBuffer)
                    processedSamples += 1

                    // Update progress if handler provided (approximate based on sample count)
                    if let progressHandler, processedSamples % 100 == 0 {
                        // Estimate progress - this is approximate
                        let estimatedProgress = min(Double(processedSamples) / (durationSeconds * 44.1), 1.0)
                        DispatchQueue.main.async {
                            progressHandler(estimatedProgress)
                        }
                    }
                }
            }
        }

        // Check for errors
        if reader.status == .failed {
            throw reader.error ?? AudioConversionError.readerFailed
        }

        if writer.status == .failed {
            throw writer.error ?? AudioConversionError.writerFailed
        }

        // Delete original if requested
        if deleteOriginal {
            try FileManager.default.removeItem(at: sourceURL)
        }

        // Create and return new FSFile
        let newFile = FSFile(
            name: outputURL.deletingPathExtension().lastPathComponent,
            extension: targetFormat.lowercased(),
            path: outputURL.path,
            type: .audio
        )

        return newFile
    }

    /// Checks if a conversion between two formats is supported
    static func isConversionSupported(from sourceFormat: String, to targetFormat: String) -> Bool {
        let source = sourceFormat.lowercased()
        let target = targetFormat.lowercased()

        // Same format is not a conversion
        if source == target {
            return false
        }

        // Define supported conversions
        // Note: MP3 encoding is not supported by AVFoundation, only decoding
        // Prevent converting from lossy to lossless (MP3 to WAV doesn't improve quality)
        let supportedConversions: [String: [String]] = [
            "wav": ["m4a"],           // Lossless to lossy: OK (compression)
            "mp3": ["m4a"],           // Lossy to lossy: OK (format change only)
            "m4a": [],                // M4A (lossy) to WAV (lossless) doesn't make sense
            "alac": ["m4a", "wav"]    // Lossless to anything: OK
        ]

        return supportedConversions[source]?.contains(target) ?? false
    }

    /// Returns the available conversion formats for a given source format
    static func availableFormats(for sourceFormat: String) -> [String] {
        let source = sourceFormat.lowercased()

        // Note: MP3 encoding is not supported by AVFoundation, only decoding
        // Prevent converting from lossy to lossless (doesn't improve quality)
        let supportedConversions: [String: [String]] = [
            "wav": ["m4a"],           // Lossless to lossy: OK (compression)
            "mp3": ["m4a"],           // Lossy to lossy: OK (format change only)
            "m4a": [],                // M4A (lossy) to WAV (lossless) doesn't make sense
            "alac": ["m4a", "wav"]    // Lossless to anything: OK
        ]

        return supportedConversions[source] ?? []
    }
}
