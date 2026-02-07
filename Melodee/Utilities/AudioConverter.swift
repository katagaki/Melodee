//
//  AudioConverter.swift
//  Melodee
//
//  Created by Claude on 2026/02/07.
//

import AVFoundation
import Foundation
import LAME

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

        // For MP3 output, use SwiftLAME encoder
        if targetFormat.lowercased() == "mp3" {
            return try await convertToMP3(
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

    /// Converts audio to MP3 using LAME encoder
    private static func convertToMP3(
        sourceFile: FSFile,
        sourceURL: URL,
        outputURL: URL,
        targetFormat: String,
        deleteOriginal: Bool,
        progressHandler: ((Double) -> Void)?
    ) async throws -> FSFile {
        return try await withCheckedThrowingContinuation { continuation in
            Task.detached {
                do {
                    // Use AVAssetReader to decode any audio format to PCM
                    let asset = AVAsset(url: sourceURL)

                    guard let audioTrack = try await asset.loadTracks(withMediaType: .audio).first else {
                        throw AudioConversionError.noAudioTrack
                    }

                    let reader = try AVAssetReader(asset: asset)

                    // Request PCM format that LAME can use
                    let outputSettings: [String: Any] = [
                        AVFormatIDKey: kAudioFormatLinearPCM,
                        AVLinearPCMBitDepthKey: 16,
                        AVLinearPCMIsBigEndianKey: false,
                        AVLinearPCMIsFloatKey: false,
                        AVLinearPCMIsNonInterleaved: false
                    ]

                    let readerOutput = AVAssetReaderTrackOutput(track: audioTrack, outputSettings: outputSettings)
                    reader.add(readerOutput)

                    guard reader.startReading() else {
                        throw AudioConversionError.readerFailed
                    }

                    // Get audio format info
                    guard let formatDescription = try await audioTrack.load(.formatDescriptions).first else {
                        throw AudioConversionError.noAudioTrack
                    }

                    let audioStreamBasicDescription = CMAudioFormatDescriptionGetStreamBasicDescription(formatDescription)
                    let sampleRate = Int32(audioStreamBasicDescription?.pointee.mSampleRate ?? 44100)
                    let channels = Int32(audioStreamBasicDescription?.pointee.mChannelsPerFrame ?? 2)

                    // Encode to MP3
                    try encodeToMP3FromReader(
                        reader: reader,
                        readerOutput: readerOutput,
                        sampleRate: sampleRate,
                        channels: channels,
                        outputURL: outputURL,
                        totalDuration: try await asset.load(.duration),
                        progressHandler: progressHandler
                    )

                    // Write minimal ID3 tag for SwiftTagger compatibility
                    try writeMinimalID3Tag(to: outputURL)

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

                    continuation.resume(returning: newFile)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
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
        // MP3 encoding is now supported via SwiftLAME library
        // Prevent converting from lossy to lossless (doesn't improve quality)
        let supportedConversions: [String: [String]] = [
            "wav": ["m4a", "mp3"],    // Lossless to lossy: OK (compression)
            "mp3": ["m4a"],           // Lossy to lossy: OK (format change only, but not to MP3)
            "m4a": ["mp3"],           // Lossy to lossy: OK (format change)
            "alac": ["m4a", "wav", "mp3"]  // Lossless to anything: OK
        ]

        return supportedConversions[source]?.contains(target) ?? false
    }

    /// Returns the available conversion formats for a given source format
    static func availableFormats(for sourceFormat: String) -> [String] {
        let source = sourceFormat.lowercased()

        // MP3 encoding is now supported via SwiftLAME library
        // Prevent converting from lossy to lossless (doesn't improve quality)
        let supportedConversions: [String: [String]] = [
            "wav": ["m4a", "mp3"],    // Lossless to lossy: OK (compression)
            "mp3": ["m4a"],           // Lossy to lossy: OK (format change only, but not to MP3)
            "m4a": ["mp3"],           // Lossy to lossy: OK (format change)
            "alac": ["m4a", "wav", "mp3"]  // Lossless to anything: OK
        ]

        return supportedConversions[source] ?? []
    }
}

// MARK: - MP3 Encoding Extension
extension AudioConverter {

    /// Encodes audio from AVAssetReader to MP3 using LAME
    fileprivate static func encodeToMP3FromReader(
        reader: AVAssetReader,
        readerOutput: AVAssetReaderTrackOutput,
        sampleRate: Int32,
        channels: Int32,
        outputURL: URL,
        totalDuration: CMTime,
        progressHandler: ((Double) -> Void)?
    ) throws {
        // Initialize and configure LAME
        guard let lame = lame_init() else {
            throw AudioConversionError.exportSessionFailed
        }
        defer { lame_close(lame) }

        lame_set_in_samplerate(lame, sampleRate)
        lame_set_num_channels(lame, channels)
        lame_set_brate(lame, 320)  // 320 kbps CBR
        lame_set_quality(lame, 2)  // 2 = high quality

        guard lame_init_params(lame) >= 0 else {
            throw AudioConversionError.exportSessionFailed
        }

        // Open output file
        guard let outputFile = fopen(outputURL.path, "wb") else {
            throw AudioConversionError.exportSessionFailed
        }
        defer { fclose(outputFile) }

        // Encode audio from reader
        let totalSeconds = CMTimeGetSeconds(totalDuration)
        var processedSeconds: Double = 0

        while reader.status == .reading {
            guard let sampleBuffer = readerOutput.copyNextSampleBuffer() else {
                break
            }

            guard let blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else {
                continue
            }

            var length: Int = 0
            var dataPointer: UnsafeMutablePointer<Int8>?

            let status = CMBlockBufferGetDataPointer(
                blockBuffer,
                atOffset: 0,
                lengthAtOffsetOut: nil,
                totalLengthOut: &length,
                dataPointerOut: &dataPointer
            )

            guard status == kCMBlockBufferNoErr, let data = dataPointer else {
                continue
            }

            // Convert to Int16 samples
            let pcmData = UnsafeRawPointer(data).assumingMemoryBound(to: Int16.self)
            let sampleCount = length / 2  // 16-bit samples
            let frameCount = Int32(sampleCount / Int(channels))

            // Calculate proper MP3 buffer size: 1.25 * samples + 7200 (per LAME documentation)
            let mp3BufferSize = Int(1.25 * Double(frameCount) + 7200)
            var mp3Buffer = [UInt8](repeating: 0, count: mp3BufferSize)

            let bytesWritten: Int32
            if channels == 2 {
                // For stereo, interleaved data needs to be split
                var leftChannel = [Int16](repeating: 0, count: Int(frameCount))
                var rightChannel = [Int16](repeating: 0, count: Int(frameCount))

                for index in 0..<Int(frameCount) {
                    leftChannel[index] = pcmData[index * 2]
                    rightChannel[index] = pcmData[index * 2 + 1]
                }

                bytesWritten = lame_encode_buffer(
                    lame,
                    &leftChannel,
                    &rightChannel,
                    frameCount,
                    &mp3Buffer,
                    Int32(mp3BufferSize)
                )
            } else {
                // Mono
                var monoChannel = [Int16](repeating: 0, count: Int(frameCount))

                for index in 0..<Int(frameCount) {
                    monoChannel[index] = pcmData[index]
                }

                bytesWritten = lame_encode_buffer(
                    lame,
                    &monoChannel,
                    &monoChannel,
                    frameCount,
                    &mp3Buffer,
                    Int32(mp3BufferSize)
                )
            }

            if bytesWritten > 0 {
                fwrite(mp3Buffer, 1, Int(bytesWritten), outputFile)
            }

            // Update progress
            let bufferDuration = CMSampleBufferGetDuration(sampleBuffer)
            processedSeconds += CMTimeGetSeconds(bufferDuration)

            if let progressHandler, totalSeconds > 0 {
                let progress = processedSeconds / totalSeconds
                DispatchQueue.main.async {
                    progressHandler(min(progress, 1.0))
                }
            }
        }

        // Check for reader errors
        if reader.status == .failed {
            throw reader.error ?? AudioConversionError.readerFailed
        }

        // Flush remaining MP3 frames (need a buffer for this)
        let flushBufferSize = 7200
        var flushBuffer = [UInt8](repeating: 0, count: flushBufferSize)
        let flushBytes = lame_encode_flush(lame, &flushBuffer, Int32(flushBufferSize))
        if flushBytes > 0 {
            fwrite(flushBuffer, 1, Int(flushBytes), outputFile)
        }

        // Write VBR/INFO tag
        lame_mp3_tags_fid(lame, outputFile)
    }

    /// Writes a minimal ID3v2.3 tag to an MP3 file to make it compatible with SwiftTagger
    fileprivate static func writeMinimalID3Tag(to url: URL) throws {
        // Read the existing MP3 data
        guard let fileHandle = try? FileHandle(forUpdating: url) else {
            return
        }
        defer { try? fileHandle.close() }

        // Check if ID3v2 tag already exists
        try fileHandle.seek(toOffset: 0)
        let header = try fileHandle.read(upToCount: 10)

        if let header = header, header.count >= 3,
           header[0] == 0x49, header[1] == 0x44, header[2] == 0x33 { // "ID3"
            // Tag already exists
            return
        }

        // Create minimal ID3v2.3 tag
        // Header: "ID3" + version (2.3) + flags + size
        var id3Tag = Data()
        id3Tag.append(contentsOf: [0x49, 0x44, 0x33]) // "ID3"
        id3Tag.append(contentsOf: [0x03, 0x00]) // Version 2.3.0
        id3Tag.append(0x00) // Flags

        // Calculate tag size (we'll use 2048 bytes for the tag body)
        let tagBodySize = 2048
        let synchsafeSize = toSynchsafeInt(tagBodySize)
        id3Tag.append(contentsOf: synchsafeSize)

        // Add padding frame
        id3Tag.append(Data(repeating: 0x00, count: tagBodySize))

        // Read original MP3 data
        try fileHandle.seek(toOffset: 0)
        let originalData = try fileHandle.readToEnd() ?? Data()

        // Write new data: ID3 tag + original MP3
        try fileHandle.seek(toOffset: 0)
        try fileHandle.write(contentsOf: id3Tag)
        try fileHandle.write(contentsOf: originalData)
        try fileHandle.truncate(atOffset: UInt64(id3Tag.count + originalData.count))
    }

    /// Converts an integer to synchsafe integer format (7 bits per byte)
    private static func toSynchsafeInt(_ value: Int) -> [UInt8] {
        return [
            UInt8((value >> 21) & 0x7F),
            UInt8((value >> 14) & 0x7F),
            UInt8((value >> 7) & 0x7F),
            UInt8(value & 0x7F)
        ]
    }
}
