//
//  MediaPlayerManager.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2023/09/11.
//

import AVFAudio
import Foundation

class MediaPlayerManager: NSObject,
                          ObservableObject,
                          AVAudioPlayerDelegate {

    var audioPlayer: AVAudioPlayer?
    @Published var isPlaybackActive: Bool = false
    @Published var isPaused: Bool = true
    @Published var queue: [FSFile] = []

    func currentlyPlayingFile() -> String? {
        if let audioPlayer = audioPlayer,
           let url = audioPlayer.url {
            return url.lastPathComponent
        } else {
            return nil
        }
    }

    func play(file: FSFile) {
        do {
            // Stop audio if it's playing
            if let audioPlayer = audioPlayer {
                audioPlayer.stop()
            }
            // Play new audio
            audioPlayer = try AVAudioPlayer(contentsOf: URL(filePath: file.path))
            play()
        } catch {
            debugPrint(error.localizedDescription)
        }
    }

    func play() {
        if let audioPlayer = audioPlayer {
            audioPlayer.delegate = self
            audioPlayer.play()
            isPlaybackActive = true
            isPaused = false
        }
    }

    func playNext(file: FSFile) {
        if audioPlayer != nil {
            queue.insert(file, at: 0)
        } else {
            play(file: file)
        }
    }

    func playLast(file: FSFile) {
        if audioPlayer != nil {
            queue.append(file)
        } else {
            play(file: file)
        }
    }

    func pause() {
        if let audioPlayer = audioPlayer {
            audioPlayer.pause()
            isPaused = true
        }
    }

    func stop() {
        if let audioPlayer = audioPlayer {
            audioPlayer.stop()
            isPlaybackActive = false
            isPaused = false
        }
    }

    func skipToNextTrack() {
        if let nextFile = queue.first {
            play(file: nextFile)
            queue.removeFirst()
        }
    }

    func canGoToNextTrack() -> Bool {
        return !queue.isEmpty
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        debugPrint("AVAudioPlayer finished playing!")
        if let nextFile = queue.first {
            play(file: nextFile)
            queue.removeFirst()
        } else {
            isPlaybackActive = false
            isPaused = true
        }
    }
}
