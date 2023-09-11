//
//  MediaPlayerManager.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2023/09/11.
//

import AVFAudio
import Foundation
import MediaPlayer

class MediaPlayerManager: NSObject,
                          ObservableObject,
                          AVAudioPlayerDelegate {

    var audioPlayer: AVAudioPlayer?
    @Published var isPlaybackActive: Bool = false
    @Published var isPaused: Bool = true
    @Published var queue: [FSFile] = []

    func currentlyPlayingFilename() -> String? {
        if let audioPlayer = audioPlayer,
           let url = audioPlayer.url {
            return url.lastPathComponent
        } else {
            return nil
        }
    }

    func currentQueueFile() -> FSFile? {
        return queue.first
    }

    func playImmediately(_ file: FSFile, addToQueue: Bool = true) {
        do {
            // Stop audio if it's playing
            if let audioPlayer = audioPlayer {
                audioPlayer.stop()
            }
            // Queue and/or play new file
            if addToQueue {
                if !queue.isEmpty {
                    queue.remove(at: 0)
                }
                queue.insert(file, at: 0)
                setQueueIDs()
            }
            audioPlayer = try AVAudioPlayer(contentsOf: URL(filePath: file.path))
            play()
        } catch {
            debugPrint(error.localizedDescription)
        }
    }

    func play() {
        do {
            if let audioPlayer = audioPlayer {
                audioPlayer.delegate = self
                audioPlayer.play()
                isPlaybackActive = true
                isPaused = false
                Task {
                    await setNowPlaying(with: audioPlayer)
                }
            } else {
                if let file = queue.first {
                    audioPlayer = try AVAudioPlayer(contentsOf: URL(filePath: file.path))
                    play()
                }
            }
        } catch {
            debugPrint(error.localizedDescription)
        }
    }

    func queueNext(file: FSFile) {
        queue.insert(file, at: max(0, min(queue.count, 1)))
        setQueueIDs()
    }

    func queueLast(file: FSFile) {
        queue.append(file)
        setQueueIDs()
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
            queue.removeAll()
            self.audioPlayer = nil
            isPlaybackActive = false
            isPaused = false
        }
    }

    func skipToNextTrack() {
        queue.removeFirst()
        if let nextFile = queue.first {
            playImmediately(nextFile, addToQueue: false)
        }
    }

    func backToStartOfTrack() {
        if let audioPlayer = audioPlayer {
            audioPlayer.currentTime = 0.0
        }
    }

    func canStartPlayback() -> Bool {
        return !queue.isEmpty
    }

    func canGoToNextTrack() -> Bool {
        return queue.count > 1
    }

    func setQueueIDs() {
        for index in 0..<queue.count where queue[index].playbackQueueID.isEmpty {
            queue[index].playbackQueueID = UUID().uuidString
        }
    }

    func setNowPlaying(with audioPlayer: AVAudioPlayer) async {
        do {
            // Set up audio session
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(AVAudioSession.Category.playback)
            try audioSession.setActive(true)
            // Set up remote controls
            let remoteCommandCenter = MPRemoteCommandCenter.shared()
            remoteCommandCenter.playCommand.isEnabled = true
            remoteCommandCenter.playCommand.addTarget { [unowned self] _ in
                if !(self.audioPlayer?.isPlaying ?? false) {
                    self.play()
                    return .success
                }
                return .commandFailed
            }
            remoteCommandCenter.pauseCommand.isEnabled = true
            remoteCommandCenter.pauseCommand.addTarget { [unowned self] _ in
                if !(self.audioPlayer?.isPlaying ?? false) {
                    self.pause()
                    return .success
                }
                return .commandFailed
            }
            // Set up now playing info center
            let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
            let albumArt = await albumArt()
            var nowPlayingInfo = [String: Any]()
            nowPlayingInfo[MPMediaItemPropertyTitle] = currentlyPlayingFilename() ?? ""
            nowPlayingInfo[MPMediaItemPropertyArtist] = Bundle.main
                .object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? ""
            nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: albumArt.size) { size in
                return albumArt
            }
            nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = audioPlayer.currentTime
            nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = audioPlayer.duration
            nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = audioPlayer.rate
            nowPlayingInfoCenter.nowPlayingInfo = nowPlayingInfo
        } catch {
            debugPrint(error.localizedDescription)
        }
    }

    func albumArt() async -> UIImage {
        do {
            if let url = audioPlayer?.url {
                let playerItem = AVPlayerItem(url: url)
                let metadataList = try await playerItem.asset.load(.metadata)
                for item in metadataList {
                    switch item.commonKey {
                    case .commonKeyArtwork?:
                        if let data = try await item.load(.dataValue),
                           let image = UIImage(data: data) {
                            return image
                        }
                    default: break
                    }
                }
            }
        } catch {
            debugPrint(error.localizedDescription)
        }
        return UIImage(named: "Album.Generic")!
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        debugPrint("AVAudioPlayer finished playing!")
        if queue.count == 1 {
            debugPrint("Killing AVAudioPlayer instance...")
            audioPlayer = nil
            queue.removeAll()
            isPlaybackActive = false
            isPaused = true
        } else {
            debugPrint("Playing next file...")
            queue.removeFirst()
            if let nextFile = queue.first {
                playImmediately(nextFile)
            }
        }
    }
}
