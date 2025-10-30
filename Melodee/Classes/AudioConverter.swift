//
//  AudioConverter.swift
//  Melodee
//
//  Created by GitHub Copilot on 2025/10/30.
//

import AVFoundation
import Foundation

enum AudioFormat: String, CaseIterable {
    case mp3 = "mp3"
    case wav = "wav"
    case m4a = "m4a"
    
    var fileExtension: String {
        return self.rawValue
    }
    
    var displayName: String {
        return self.rawValue.uppercased()
    }
    
    var outputFileType: AVFileType {
        switch self {
        case .mp3:
            return .mp3
        case .wav:
            return .wav
        case .m4a:
            return .m4a
        }
    }
}

@Observable
class AudioConverter {
    var progress: Progress?
    
    func convert(inputFile: FSFile, 
                 outputFormat: AudioFormat,
                 completion: @escaping (Result<FSFile, Error>) -> Void) {
        
        let inputURL = URL(fileURLWithPath: inputFile.path)
        let outputFileName = "\(inputFile.name).\(outputFormat.fileExtension)"
        let outputURL = inputURL.deletingLastPathComponent().appendingPathComponent(outputFileName)
        
        // If output file already exists, add a number suffix
        let finalOutputURL = getUniqueOutputURL(baseURL: outputURL)
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            do {
                try self.performConversion(inputURL: inputURL, 
                                          outputURL: finalOutputURL, 
                                          outputFormat: outputFormat)
                
                let outputFile = FSFile(
                    name: finalOutputURL.deletingPathExtension().lastPathComponent,
                    extension: outputFormat.fileExtension,
                    path: finalOutputURL.path,
                    type: .audio
                )
                
                DispatchQueue.main.async {
                    completion(.success(outputFile))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    private func performConversion(inputURL: URL, 
                                   outputURL: URL, 
                                   outputFormat: AudioFormat) throws {
        let asset = AVAsset(url: inputURL)
        
        // Remove existing file if present
        if FileManager.default.fileExists(atPath: outputURL.path) {
            try FileManager.default.removeItem(at: outputURL)
        }
        
        // Create asset reader
        let assetReader = try AVAssetReader(asset: asset)
        guard let audioTrack = asset.tracks(withMediaType: .audio).first else {
            throw NSError(domain: "AudioConverter", code: 1, 
                         userInfo: [NSLocalizedDescriptionKey: "No audio track found"])
        }
        
        let outputSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsNonInterleaved: false
        ]
        
        let assetReaderOutput = AVAssetReaderTrackOutput(track: audioTrack, 
                                                         outputSettings: outputSettings)
        assetReader.add(assetReaderOutput)
        
        // Create asset writer
        let assetWriter = try AVAssetWriter(outputURL: outputURL, 
                                           fileType: outputFormat.outputFileType)
        
        let writerSettings = getWriterSettings(for: outputFormat, from: audioTrack)
        let assetWriterInput = AVAssetWriterInput(mediaType: .audio, 
                                                  outputSettings: writerSettings)
        assetWriterInput.expectsMediaDataInRealTime = false
        assetWriter.add(assetWriterInput)
        
        // Start conversion
        assetReader.startReading()
        assetWriter.startWriting()
        assetWriter.startSession(atSourceTime: .zero)
        
        let mediaInputQueue = DispatchQueue(label: "audioConverterQueue")
        
        let semaphore = DispatchSemaphore(value: 0)
        var conversionError: Error?
        
        assetWriterInput.requestMediaDataWhenReady(on: mediaInputQueue) {
            while assetWriterInput.isReadyForMoreMediaData {
                if let sampleBuffer = assetReaderOutput.copyNextSampleBuffer() {
                    assetWriterInput.append(sampleBuffer)
                } else {
                    assetWriterInput.markAsFinished()
                    break
                }
            }
            
            if assetReader.status == .completed {
                assetWriter.finishWriting {
                    if assetWriter.status == .failed {
                        conversionError = assetWriter.error
                    }
                    semaphore.signal()
                }
            } else if assetReader.status == .failed {
                conversionError = assetReader.error
                semaphore.signal()
            }
        }
        
        semaphore.wait()
        
        if let error = conversionError {
            throw error
        }
    }
    
    private func getWriterSettings(for format: AudioFormat, from track: AVAssetTrack) -> [String: Any] {
        switch format {
        case .mp3:
            return [
                AVFormatIDKey: kAudioFormatMPEGLayer3,
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 2,
                AVEncoderBitRateKey: 320000
            ]
        case .wav:
            return [
                AVFormatIDKey: kAudioFormatLinearPCM,
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 2,
                AVLinearPCMBitDepthKey: 16,
                AVLinearPCMIsFloatKey: false,
                AVLinearPCMIsBigEndianKey: false,
                AVLinearPCMIsNonInterleaved: false
            ]
        case .m4a:
            return [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 2,
                AVEncoderBitRateKey: 256000
            ]
        }
    }
    
    private func getUniqueOutputURL(baseURL: URL) -> URL {
        var outputURL = baseURL
        var counter = 1
        
        while FileManager.default.fileExists(atPath: outputURL.path) {
            let fileName = baseURL.deletingPathExtension().lastPathComponent
            let ext = baseURL.pathExtension
            let newFileName = "\(fileName) (\(counter)).\(ext)"
            outputURL = baseURL.deletingLastPathComponent().appendingPathComponent(newFileName)
            counter += 1
        }
        
        return outputURL
    }
}
