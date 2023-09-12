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

    let notificationCenter = NotificationCenter.default
    let audioSession = AVAudioSession.sharedInstance()
    let remoteCommandCenter = MPRemoteCommandCenter.shared()
    let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
    var audioPlayer: AVAudioPlayer?
    @Published var isPlaybackActive: Bool = false
    @Published var isPaused: Bool = true
    @Published var queue: [FSFile] = []
    @Published var currentlyPlayingID: String = ""

    override init() {
        super.init()
        do {
            // Set up audio session
            try audioSession.setCategory(AVAudioSession.Category.playback)
            try audioSession.setActive(true)
            // Set up remote controls
            remoteCommandCenter.playCommand.addTarget { _ in
                if let audioPlayer = self.audioPlayer,
                   !audioPlayer.isPlaying {
                    self.play()
                    return .success
                }
                return .commandFailed
            }
            remoteCommandCenter.pauseCommand.addTarget { _ in
                if let audioPlayer = self.audioPlayer,
                   audioPlayer.isPlaying {
                    self.pause()
                    return .success
                }
                return .commandFailed
            }
            remoteCommandCenter.nextTrackCommand.addTarget { _ in
                self.skipToNextTrack()
                return .success
            }
            remoteCommandCenter.previousTrackCommand.addTarget { _ in
                self.backToPreviousTrack()
                return .success
            }
            remoteCommandCenter.changePlaybackPositionCommand.addTarget { event in
                if let event = event as? MPChangePlaybackPositionCommandEvent {
                    self.seekTo(event.positionTime)
                    return .success
                }
                return .commandFailed
            }
            // Set up interruption notification observer
            notificationCenter.addObserver(self,
                                           selector: #selector(handleInterruption),
                                           name: AVAudioSession.interruptionNotification,
                                           object: AVAudioSession.sharedInstance())
        } catch {
            debugPrint(error.localizedDescription)
        }
    }

    func currentlyPlayingFilename() -> String? {
        if let audioPlayer = audioPlayer,
           let url = audioPlayer.url {
            return url.lastPathComponent
        } else {
            return nil
        }
    }

    func currentlyPlayingFile() -> FSFile? {
        return queue.first(where: { $0.playbackQueueID == currentlyPlayingID })
    }

    func currentlyPlayingIndex() -> Int {
        return queue.firstIndex(where: { $0.playbackQueueID == currentlyPlayingID }) ?? 0
    }

    func canStartPlayback() -> Bool {
        return !queue.isEmpty
    }

    func canGoToNextTrack() -> Bool {
        return currentlyPlayingIndex() < queue.count - 1
    }

    func canGoToPreviousTrack() -> Bool {
        return currentlyPlayingIndex() > 0
    }

    func playImmediately(_ file: FSFile, addToQueue: Bool = true) {
        // Stop audio if it's playing
        if let audioPlayer = audioPlayer {
            audioPlayer.stop()
        }
        // Queue and/or play new file
        let currentlyPlayingIndex = currentlyPlayingIndex()
        if addToQueue {
            queue.insert(file, at: currentlyPlayingIndex)
            setQueueIDs()
        }
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: URL(filePath: file.path))
            if file.playbackQueueID == "" {
                currentlyPlayingID = queue[currentlyPlayingIndex].playbackQueueID
            } else {
                currentlyPlayingID = file.playbackQueueID
            }
            play()
        } catch {
            debugPrint(error.localizedDescription)
            skipToNextTrack()
        }
    }

    func play() {
        if let audioPlayer = audioPlayer {
            audioPlayer.delegate = self
            audioPlayer.play()
            isPlaybackActive = true
            isPaused = false
            setNowPlaying()
        } else {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: URL(filePath: queue[currentlyPlayingIndex()].path))
                currentlyPlayingID = queue[currentlyPlayingIndex()].playbackQueueID
                play()
            } catch {
                debugPrint(error.localizedDescription)
                skipToNextTrack()
            }
        }
    }

    func queueNext(file: FSFile) {
        queue.insert(file, at: currentlyPlayingIndex() + 1)
        setQueueIDs()
        setNowPlaying()
    }

    func queueLast(file: FSFile) {
        queue.append(file)
        setQueueIDs()
        setNowPlaying()
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
            currentlyPlayingID = ""
            isPlaybackActive = false
            isPaused = false
        }
    }

    func skipToNextTrack() {
        if canGoToNextTrack() {
            playImmediately(queue[currentlyPlayingIndex() + 1], addToQueue: false)
        } else {
            setNowPlaying()
        }
    }

    func backToPreviousTrack() {
        if canGoToPreviousTrack() {
            playImmediately(queue[currentlyPlayingIndex() - 1], addToQueue: false)
        } else {
            setNowPlaying()
        }
    }

    func seekTo(_ time: TimeInterval) {
        if let audioPlayer = audioPlayer {
            audioPlayer.currentTime = time
            setNowPlaying()
        }
    }

    func setQueueIDs() {
        for index in 0..<queue.count where queue[index].playbackQueueID.isEmpty {
            queue[index].playbackQueueID = UUID().uuidString
        }
    }

    func setNowPlaying() {
        if let audioPlayer = audioPlayer {
            Task {
                await setNowPlaying(with: audioPlayer)
            }
        }
    }

    func setNowPlaying(with audioPlayer: AVAudioPlayer) async {
        // Set remote command center command enable/disable
        remoteCommandCenter.playCommand.isEnabled = canStartPlayback()
        remoteCommandCenter.pauseCommand.isEnabled = audioPlayer.isPlaying
        remoteCommandCenter.nextTrackCommand.isEnabled = canGoToNextTrack()
        remoteCommandCenter.previousTrackCommand.isEnabled = audioPlayer.isPlaying
        remoteCommandCenter.changePlaybackPositionCommand.isEnabled = audioPlayer.isPlaying
        // Set now playing info
        let albumArt = await albumArt()
        var nowPlayingInfo = [String: Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = currentlyPlayingFilename() ?? ""
        nowPlayingInfo[MPMediaItemPropertyArtist] = Bundle.main
            .object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? ""
        nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: albumArt.size) { _ in
            return albumArt
        }
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = audioPlayer.currentTime
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = audioPlayer.duration
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = audioPlayer.rate
        nowPlayingInfoCenter.nowPlayingInfo = nowPlayingInfo
    }

    @objc func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
            let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
                return
        }
        switch type {
        case .began:
            isPaused = true
        case .ended:
            guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else { return }
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            if options.contains(.shouldResume) {
                isPaused = false
            }
        default: ()
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
        if currentlyPlayingIndex() == queue.count - 1 {
            debugPrint("Killing AVAudioPlayer instance...")
            audioPlayer = nil
            nowPlayingInfoCenter.nowPlayingInfo = nil
            isPlaybackActive = false
            isPaused = true
        } else {
            debugPrint("Playing next file...")
            playImmediately(queue[currentlyPlayingIndex() + 1])
        }
    }
}
