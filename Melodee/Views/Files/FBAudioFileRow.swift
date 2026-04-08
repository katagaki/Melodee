//
//  FBAudioFileRow.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2023/09/12.
//

import SwiftTagger
import SwiftUI

struct FBAudioFileRow: View {

    @Environment(MediaPlayerManager.self) var mediaPlayer
    @Environment(FileDownloadManager.self) var downloadManager

    @State var file: FSFile
    var sortOption: SortOption = .fileName
    @State var tagSubtitle: String?

    var body: some View {
        Button {
            if file.isEvicted() {
                downloadManager.startDownload(for: file) {
                    mediaPlayer.playImmediately(file)
                }
            } else {
                mediaPlayer.playImmediately(file)
            }
        } label: {
            ListFileRow(file: .constant(file), subtitle: tagSubtitle)
                .tint(.primary)
        }
        .task(id: sortOption) {
            // Don't read tags from evicted iCloud files
            guard !file.isEvicted() else { return }
            tagSubtitle = readTagSubtitle()
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
                if file.isEvicted() {
                    downloadManager.startDownload(for: file) {
                        withAnimation(.default.speed(2)) {
                            mediaPlayer.queueNext(file: file)
                        }
                    }
                } else {
                    withAnimation(.default.speed(2)) {
                        mediaPlayer.queueNext(file: file)
                    }
                }
            } label: {
                Label("Shared.Play.Next",
                      systemImage: "text.line.first.and.arrowtriangle.forward")
            }
            .tint(.purple)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button {
                if file.isEvicted() {
                    downloadManager.startDownload(for: file) {
                        withAnimation(.default.speed(2)) {
                            mediaPlayer.queueLast(file: file)
                        }
                    }
                } else {
                    withAnimation(.default.speed(2)) {
                        mediaPlayer.queueLast(file: file)
                    }
                }
            } label: {
                Label("Shared.Play.Last",
                      systemImage: "text.line.last.and.arrowtriangle.forward")
            }
            .tint(.orange)
        }
    }

    func readTagSubtitle() -> String? {
        guard sortOption != .fileName, file.isTaggableAudio() else {
            return nil
        }
        do {
            let audioFile = try AudioFile(location: URL(fileURLWithPath: file.path))
            switch sortOption {
            case .fileName:
                return nil
            case .trackTitle:
                let title = audioFile.title ?? ""
                return title.isEmpty ? nil : title
            case .trackNumber:
                let track = audioFile.trackNumber.index
                return track != 0 ? String(track) : nil
            case .albumName:
                let album = audioFile.album ?? ""
                return album.isEmpty ? nil : album
            case .artistName:
                let artist = audioFile.artist ?? ""
                return artist.isEmpty ? nil : artist
            }
        } catch {
            debugPrint("Error reading tag for subtitle: \(error.localizedDescription)")
            return nil
        }
    }
}
