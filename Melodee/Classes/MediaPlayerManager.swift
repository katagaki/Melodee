//
//  MediaPlayerManager.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2023/09/11.
//

@preconcurrency import AVFAudio
import Foundation
@preconcurrency import MediaPlayer
import SFBAudioEngine
import UIKit

// swiftlint:disable type_body_length file_length
@Observable
class MediaPlayerManager: NSObject, AudioPlayer.Delegate {

    @ObservationIgnored let notificationCenter = NotificationCenter.default
    @ObservationIgnored let audioSession = AVAudioSession.sharedInstance()
    @ObservationIgnored let remoteCommandCenter = MPRemoteCommandCenter.shared()
    @ObservationIgnored let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
    @ObservationIgnored let audioPlayer = AudioPlayer()
    @ObservationIgnored var downloadManager: FileDownloadManager?
    var isPlaybackActive: Bool = false
    var isPaused: Bool = true
    var repeatMode: RepeatMode = .none
    var queue: [FSFile] = []
    var currentlyPlayingID: String = ""

    override init() {
        super.init()
        audioPlayer.delegate = self
        // Set up remote controls
        remoteCommandCenter.playCommand.addTarget { _ in
            if !self.audioPlayer.isPlaying, self.canStartPlayback() {
                self.play()
                return .success
            }
            return .commandFailed
        }
        remoteCommandCenter.pauseCommand.addTarget { _ in
            if self.audioPlayer.isPlaying {
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
    }

    func currentlyPlayingTitle() -> String? {
        guard isPlaybackActive, let file = currentlyPlayingFile() else { return nil }
        if file.isTaggableAudio(), let title = try? readMetadata(for: file)?.title, !title.isEmpty {
            return title
        }
        return file.name
    }

    func currentlyPlayingArtistName() -> String? {
        guard isPlaybackActive, let file = currentlyPlayingFile() else { return nil }
        if file.isTaggableAudio(), let artist = try? readMetadata(for: file)?.artist, !artist.isEmpty {
            return artist
        }
        return NSLocalizedString("Shared.UnknownArtist", comment: "")
    }

    func currentlyPlayingAlbumName() -> String? {
        guard isPlaybackActive, let file = currentlyPlayingFile() else { return nil }
        if file.isTaggableAudio(), let album = try? readMetadata(for: file)?.albumTitle, !album.isEmpty {
            return album
        }
        return file.containingFolderName()
    }

    private func readMetadata(for file: FSFile) throws -> AudioMetadata? {
        let fileURL = URL(fileURLWithPath: file.path)
        return try AudioFile(readingPropertiesAndMetadataFrom: fileURL).metadata
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
        audioPlayer.stop()
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
        activateAudioSession()
        let url = URL(fileURLWithPath: file.path)
        do {
            try audioPlayer.play(url)
            isPlaybackActive = true
            isPaused = false
            setNowPlaying()
        } catch {
            debugPrint("Failed to start playback: \(error.localizedDescription)")
            if canGoToNextTrack() {
                skipToNextTrack()
            } else {
                stop()
            }
        }
    }

    private func activateAudioSession() {
        MainActor.assumeIsolated {
            UIApplication.shared.beginReceivingRemoteControlEvents()
        }
        do {
            try audioSession.setCategory(AVAudioSession.Category.playback)
            try audioSession.setActive(true)
        } catch {
            debugPrint(error.localizedDescription)
        }
    }

    func play() {
        activateAudioSession()
        if audioPlayer.isPaused {
            do {
                try audioPlayer.play()
                isPlaybackActive = true
                isPaused = false
                setNowPlaying()
                return
            } catch {
                debugPrint("Failed to resume playback: \(error.localizedDescription)")
            }
        }
        if audioPlayer.isPlaying {
            isPlaybackActive = true
            isPaused = false
            setNowPlaying()
            return
        }
        // Stopped — start from the queue.
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
        audioPlayer.pause()
        isPaused = true
    }

    func stop() {
        audioPlayer.stop()
        queue.removeAll()
        currentlyPlayingID = ""
        nowPlayingInfoCenter.nowPlayingInfo = nil
        isPlaybackActive = false
        isPaused = true
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
        guard audioPlayer.supportsSeeking else { return }
        audioPlayer.seek(time: time)
        setNowPlaying()
    }

    func setQueueIDs() {
        for index in 0..<queue.count where queue[index].playbackQueueID.isEmpty {
            queue[index].playbackQueueID = UUID().uuidString
        }
    }

    func setNowPlaying() {
        nonisolated(unsafe) let managerRef = self
        Task { @MainActor in
            await managerRef.setNowPlayingOnMain()
        }
    }

    @MainActor
    private func setNowPlayingOnMain() async {
        // Set remote command center command enable/disable
        let playing = audioPlayer.isPlaying
        remoteCommandCenter.playCommand.isEnabled = canStartPlayback()
        remoteCommandCenter.pauseCommand.isEnabled = playing
        remoteCommandCenter.nextTrackCommand.isEnabled = canGoToNextTrack()
        remoteCommandCenter.previousTrackCommand.isEnabled = canGoToPreviousTrack()
        remoteCommandCenter.changePlaybackPositionCommand.isEnabled = playing && audioPlayer.supportsSeeking
        // Set now playing info
        let albumArt = albumArt()
        var nowPlayingInfo = [String: Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = currentlyPlayingTitle() ?? ""
        nowPlayingInfo[MPMediaItemPropertyArtist] = "Melodee"
        nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: albumArt.size) { _ in
            return albumArt
        }
        if let time = audioPlayer.time {
            nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = time.currentTime
            nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = time.totalTime
        }
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = playing ? 1.0 : 0.0
        nowPlayingInfoCenter.nowPlayingInfo = nowPlayingInfo
    }

    func albumArt() -> UIImage {
        if let file = currentlyPlayingFile(),
           let metadata = try? readMetadata(for: file),
           let picture = metadata.attachedPictures(ofType: .frontCover).first
            ?? metadata.attachedPictures.first,
           let image = UIImage(data: picture.imageData) {
            return image
        }
        return UIImage(named: "Album.Generic") ?? UIImage()
    }

    // MARK: - AudioPlayerDelegate

    func audioPlayer(_ audioPlayer: AudioPlayer, renderingComplete decoder: PCMDecoding) {
        nonisolated(unsafe) let managerRef = self
        Task { @MainActor in
            managerRef.handleRenderingComplete()
        }
    }

    func audioPlayer(_ audioPlayer: AudioPlayer, nowPlayingChanged nowPlaying: PCMDecoding?) {
        nonisolated(unsafe) let managerRef = self
        Task { @MainActor in
            managerRef.setNowPlaying()
        }
    }

    func audioPlayer(_ audioPlayer: AudioPlayer, playbackStateChanged playbackState: AudioPlayer.PlaybackState) {
        nonisolated(unsafe) let managerRef = self
        let isNowPaused = playbackState != .playing
        Task { @MainActor in
            managerRef.isPaused = isNowPaused
            if playbackState == .playing {
                managerRef.isPlaybackActive = true
            }
            managerRef.setNowPlaying()
        }
    }

    func audioPlayer(_ audioPlayer: AudioPlayer, encounteredError error: Error) {
        debugPrint("SFBAudioEngine error: \(error.localizedDescription)")
    }

    func audioPlayer(
        _ audioPlayer: AudioPlayer,
        audioSessionInterruption notification: Notification,
        userInfo: [AnyHashable: Any]
    ) {
        guard let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        nonisolated(unsafe) let managerRef = self
        switch type {
        case .began:
            Task { @MainActor in managerRef.isPaused = true }
        case .ended:
            guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else { return }
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            if options.contains(.shouldResume) {
                Task { @MainActor in managerRef.isPaused = false }
            }
        default: ()
        }
    }

    @MainActor
    private func handleRenderingComplete() {
        debugPrint("SFBAudioEngine finished rendering track.")
        let index = currentlyPlayingIndex()
        guard !queue.isEmpty, index < queue.count else {
            debugPrint("Queue is empty or index out of bounds, stopping playback.")
            stop()
            return
        }
        switch repeatMode {
        case .none:
            if index >= queue.count - 1 {
                debugPrint("Reached end of queue.")
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
// swiftlint:enable type_body_length file_length
