//
//  MediaPlayerManager.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2023/09/11.
//

@preconcurrency import AVFAudio
import Foundation
@preconcurrency import MediaPlayer
import SwiftOGG
import SwiftTagger

// swiftlint:disable type_body_length
@Observable
class MediaPlayerManager: NSObject, AVAudioPlayerDelegate {

    @ObservationIgnored let notificationCenter = NotificationCenter.default
    @ObservationIgnored let audioSession = AVAudioSession.sharedInstance()
    @ObservationIgnored let remoteCommandCenter = MPRemoteCommandCenter.shared()
    @ObservationIgnored let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
    @ObservationIgnored var audioPlayer: AVAudioPlayer?
    @ObservationIgnored var downloadManager: FileDownloadManager?
    /// Temporary M4A file decoded from an OGG source for the current track.
    /// Kept so it can be cleaned up when playback moves on.
    @ObservationIgnored private var temporaryDecodedURL: URL?
    var isPlaybackActive: Bool = false
    var isPaused: Bool = true
    var repeatMode: RepeatMode = .none
    var queue: [FSFile] = []
    var currentlyPlayingID: String = ""

    override init() {
        super.init()
        // Set up remote controls
        remoteCommandCenter.playCommand.addTarget { _ in
            if let audioPlayer = self.audioPlayer, !audioPlayer.isPlaying {
                self.play()
                return .success
            }
            return .commandFailed
        }
        remoteCommandCenter.pauseCommand.addTarget { _ in
            if let audioPlayer = self.audioPlayer, audioPlayer.isPlaying {
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
    }

    func currentlyPlayingTitle() -> String? {
        if audioPlayer != nil, let file = currentlyPlayingFile() {
            if file.isTaggableAudio() {
                do {
                    let fileURL = URL(fileURLWithPath: file.path)
                    let audioFile = try AudioFile(location: fileURL)
                    return audioFile.title ?? file.name
                } catch {
                    debugPrint(error.localizedDescription)
                }
            }
            return file.name
        } else {
            return nil
        }
    }

    func currentlyPlayingArtistName() -> String? {
        if audioPlayer != nil, let file = currentlyPlayingFile() {
            if file.isTaggableAudio() {
                do {
                    let fileURL = URL(fileURLWithPath: file.path)
                    let audioFile = try AudioFile(location: fileURL)
                    return audioFile.artist ?? NSLocalizedString("Shared.UnknownArtist", comment: "")
                } catch {
                    debugPrint(error.localizedDescription)
                }
            }
            return NSLocalizedString("Shared.UnknownArtist", comment: "")
        } else {
            return nil
        }
    }

    func currentlyPlayingAlbumName() -> String? {
        if audioPlayer != nil, let file = currentlyPlayingFile() {
            if file.isTaggableAudio() {
                do {
                    let fileURL = URL(fileURLWithPath: file.path)
                    let audioFile = try AudioFile(location: fileURL)
                    return audioFile.album ?? file.containingFolderName()
                } catch {
                    debugPrint(error.localizedDescription)
                }
            }
            return file.containingFolderName()
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
        guard !queue.isEmpty else { return false }
        return currentlyPlayingIndex() < queue.count - 1
    }

    func canGoToPreviousTrack() -> Bool {
        guard !queue.isEmpty else { return false }
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
        // Set the currently playing ID before attempting playback
        if file.playbackQueueID.isEmpty, currentlyPlayingIndex < queue.count {
            currentlyPlayingID = queue[currentlyPlayingIndex].playbackQueueID
        } else {
            currentlyPlayingID = file.playbackQueueID
        }
        // If the file is evicted from iCloud, download it first
        if file.isEvicted(), let downloadManager {
            isPlaybackActive = true
            isPaused = true
            downloadManager.startDownload(for: file) { [weak self] in
                self?.loadAndPlay(file)
            }
            return
        }
        loadAndPlay(file)
    }

    private func loadAndPlay(_ file: FSFile) {
        // AVAudioPlayer can't decode Opus-in-OGG, so transcode to a temporary M4A first.
        if file.extension.lowercased() == "ogg" {
            let sourceURL = URL(filePath: file.path)
            let requestedID = currentlyPlayingID
            // Show a loading state while the decoder runs.
            isPlaybackActive = true
            isPaused = true
            Task.detached(priority: .userInitiated) { [weak self] in
                do {
                    let tempURL = FileManager.default.temporaryDirectory
                        .appendingPathComponent(UUID().uuidString)
                        .appendingPathExtension("m4a")
                    try OGGConverter.convertOpusOGGToM4aFile(src: sourceURL, dest: tempURL)
                    await MainActor.run {
                        guard let self else { return }
                        // If the user skipped to another track while we were decoding, discard.
                        guard self.currentlyPlayingID == requestedID else {
                            try? FileManager.default.removeItem(at: tempURL)
                            return
                        }
                        self.cleanUpTemporaryDecodedFile()
                        self.temporaryDecodedURL = tempURL
                        self.loadAndPlayFromURL(tempURL)
                    }
                } catch {
                    debugPrint("OGG decode failed: \(error.localizedDescription)")
                    await MainActor.run {
                        guard let self else { return }
                        if self.canGoToNextTrack() {
                            self.skipToNextTrack()
                        } else {
                            self.stop()
                        }
                    }
                }
            }
            return
        }
        cleanUpTemporaryDecodedFile()
        loadAndPlayFromURL(URL(filePath: file.path))
    }

    private func loadAndPlayFromURL(_ url: URL) {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            play()
        } catch {
            debugPrint(error.localizedDescription)
            if canGoToNextTrack() {
                skipToNextTrack()
            } else {
                stop()
            }
        }
    }

    private func cleanUpTemporaryDecodedFile() {
        if let url = temporaryDecodedURL {
            try? FileManager.default.removeItem(at: url)
            temporaryDecodedURL = nil
        }
    }

    func play() {
        // Set up audio session
        MainActor.assumeIsolated {
            UIApplication.shared.beginReceivingRemoteControlEvents()
        }
        do {
            try audioSession.setCategory(AVAudioSession.Category.playback)
            try audioSession.setActive(true)
        } catch {
            debugPrint(error.localizedDescription)
        }
        // Play audio
        if let audioPlayer = audioPlayer {
            audioPlayer.delegate = self
            audioPlayer.play()
            isPlaybackActive = true
            isPaused = false
            setNowPlaying()
        } else {
            let index = currentlyPlayingIndex()
            guard !queue.isEmpty, index < queue.count else { return }
            let file = queue[index]
            currentlyPlayingID = file.playbackQueueID
            if file.isEvicted(), let downloadManager {
                isPlaybackActive = true
                isPaused = true
                downloadManager.startDownload(for: file) { [weak self] in
                    self?.loadAndPlay(file)
                }
            } else {
                loadAndPlay(file)
            }
        }
    }

    func queueNext(file: FSFile) {
        queue.insert(file, at: min(queue.count, currentlyPlayingIndex() + 1))
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
        }
        queue.removeAll()
        self.audioPlayer = nil
        currentlyPlayingID = ""
        nowPlayingInfoCenter.nowPlayingInfo = nil
        isPlaybackActive = false
        isPaused = true
        cleanUpTemporaryDecodedFile()
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
            nonisolated(unsafe) let managerRef = self
            Task { @MainActor in
                await managerRef.setNowPlaying(with: audioPlayer)
            }
        }
    }

    func setNowPlaying(with audioPlayer: AVAudioPlayer) async {
        // Set remote command center command enable/disable
        remoteCommandCenter.playCommand.isEnabled = canStartPlayback()
        remoteCommandCenter.pauseCommand.isEnabled = audioPlayer.isPlaying
        remoteCommandCenter.nextTrackCommand.isEnabled = canGoToNextTrack()
        remoteCommandCenter.previousTrackCommand.isEnabled = canGoToPreviousTrack()
        remoteCommandCenter.changePlaybackPositionCommand.isEnabled = audioPlayer.isPlaying
        // Set now playing info
        let albumArt = await albumArt()
        var nowPlayingInfo = [String: Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = currentlyPlayingTitle() ?? ""
        nowPlayingInfo[MPMediaItemPropertyArtist] = "Melodee"
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
                let asset = AVURLAsset(url: url)
                let metadataList = try await asset.load(.metadata)
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
        return UIImage(named: "Album.Generic") ?? UIImage()
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        debugPrint("AVAudioPlayer finished playing!")
        let index = currentlyPlayingIndex()
        guard !queue.isEmpty, index < queue.count else {
            debugPrint("Queue is empty or index out of bounds, stopping playback.")
            stop()
            return
        }
        switch repeatMode {
        case .none:
            if index >= queue.count - 1 {
                debugPrint("Killing AVAudioPlayer instance...")
                audioPlayer = nil
                nowPlayingInfoCenter.nowPlayingInfo = nil
                isPlaybackActive = false
                isPaused = true
            } else {
                debugPrint("Playing next file...")
                playImmediately(queue[index + 1], addToQueue: false)
            }
        case .single:
            debugPrint("Repeating current file...")
            playImmediately(queue[index], addToQueue: false)
        case .all:
            if index >= queue.count - 1 {
                debugPrint("Repeating queue...")
                playImmediately(queue[0], addToQueue: false)
            } else {
                debugPrint("Playing next file...")
                playImmediately(queue[index + 1], addToQueue: false)
            }
        }
    }
}
// swiftlint:enable type_body_length
