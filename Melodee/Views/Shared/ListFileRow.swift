//
//  ListFileRow.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2023/09/11.
//

@preconcurrency import AVFoundation
import SwiftUI

struct ListFileRow: View {

    @Environment(MediaPlayerManager.self) var mediaPlayer
    @Environment(FileDownloadManager.self) var downloadManager

    @Binding var file: FSFile
    var subtitle: String?
    @State var thumbnail: UIImage?
    @State var isThumbnailFetchCompleted: Bool = false

    var body: some View {
        HStack(alignment: .center, spacing: 16.0) {
            if file.isTaggableAudio() || file.type == .image,
               let thumbnail = thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 28.0, height: 28.0)
                    .clipShape(RoundedRectangle(cornerRadius: 6.0))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6.0)
                            .stroke(.primary, lineWidth: 1/3)
                            .opacity(0.3)
                    )
                    .overlay(alignment: .bottomTrailing) {
                        file.type.icon()
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16.0, height: 16.0)
                            .foregroundStyle(file.type.iconColor)
                            .offset(x: 6.0, y: 6.0)
                    }
            } else {
                file.type.icon()
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28.0, height: 28.0)
                    .foregroundStyle(file.type.iconColor)
            }
            VStack(alignment: .leading, spacing: 2.0) {
                Text(file.name)
                    .font(.body)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Text(subtitle ?? URL(filePath: file.path).fileSizeString)
                    .font(.caption)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if downloadManager.isDownloading(file) {
                if let progress = downloadManager.progress(for: file), progress > 0.0 {
                    CircularProgressView(progress: progress)
                        .frame(width: 16.0, height: 16.0)
                } else {
                    ProgressView()
                        .controlSize(.small)
                }
            } else if file.isEvicted() {
                Image(systemName: "icloud.and.arrow.down")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            if file.type == .audio {
                Text(file.extension.uppercased())
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6.0)
                    .padding(.vertical, 3.0)
                    .background(.tertiary)
                    .clipShape(RoundedRectangle(cornerRadius: 4.0))
            }
        }
        .task {
            if !isThumbnailFetchCompleted {
                // Don't try to read thumbnails from evicted iCloud files
                guard !file.isEvicted() else {
                    isThumbnailFetchCompleted = true
                    return
                }
                let filePath = file.path
                let isTaggable = file.isTaggableAudio()
                let isImage = file.type == .image
                Task.detached {
                    let fileURL: URL = URL(filePath: filePath)
                    if isTaggable {
                        NSFileCoordinator().coordinate(readingItemAt: fileURL, error: .none) { url in
                            Task { @MainActor in
                                let albumArt = await albumArt(at: url)
                                withAnimation(.default.speed(2)) {
                                    self.thumbnail = albumArt
                                }
                            }
                        }
                    } else if isImage {
                        NSFileCoordinator().coordinate(readingItemAt: fileURL, error: .none) { url in
                            Task { @MainActor in
                                if let thumbnail = await UIImage(contentsOfFile: url.path(percentEncoded: false))?
                                    .byPreparingThumbnail(ofSize: CGSize(width: 100.0, height: 100.0)) {
                                    withAnimation(.default.speed(2)) {
                                        self.thumbnail = thumbnail
                                    }
                                }
                            }
                        }
                    }
                }
                isThumbnailFetchCompleted = true
            }
        }
    }

    func albumArt(at url: URL) async -> UIImage {
        do {
            let asset = AVURLAsset(url: url)
            let metadataList = try await asset.load(.metadata)
            for item in metadataList {
                switch item.commonKey {
                case .commonKeyArtwork?:
                    if let data = try await item.load(.dataValue),
                       let image = UIImage(data: data),
                       let thumbnail = await image.byPreparingThumbnail(ofSize: CGSize(width: 100.0,
                                                                                       height: 100.0)) {
                        return thumbnail
                    }
                default: break
                }
            }
        } catch {
            debugPrint(error.localizedDescription)
        }
        return UIImage(named: "Album.Generic") ?? UIImage()
    }

}
