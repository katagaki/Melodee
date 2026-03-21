//
//  PlaylistRow.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2024/03/16.
//

@preconcurrency import AVFoundation
import SwiftUI

struct PlaylistRow: View {

    var playlist: Playlist
    @State var thumbnail: UIImage?

    var body: some View {
        HStack(alignment: .center, spacing: 16.0) {
            if let thumbnail = thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 44.0, height: 44.0)
                    .clipShape(RoundedRectangle(cornerRadius: 8.0))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8.0)
                            .stroke(.primary, lineWidth: 1/3)
                            .opacity(0.3)
                    )
            } else {
                Image("Album.Generic")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 44.0, height: 44.0)
                    .clipShape(RoundedRectangle(cornerRadius: 8.0))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8.0)
                            .stroke(.primary, lineWidth: 1/3)
                            .opacity(0.3)
                    )
            }
            VStack(alignment: .leading, spacing: 2.0) {
                Text(playlist.name)
                    .font(.body)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Text(songCountText())
                    .font(.caption)
                    .lineLimit(1)
                    .foregroundStyle(.secondary)
            }
        }
        .task {
            await loadThumbnail()
        }
    }

    func songCountText() -> String {
        let audioCount = playlist.sortedBookmarks.filter { bookmark in
            FilesystemManager.fileType(forExtension: bookmark.fileExtension) == .audio
        }.count
        let totalCount = playlist.fileBookmarks.count
        if totalCount == 0 {
            return NSLocalizedString("Playlists.NoItems", comment: "")
        } else if audioCount == totalCount {
            return String(format: NSLocalizedString("Playlists.SongCount", comment: ""), audioCount)
        } else {
            return String(format: NSLocalizedString("Playlists.ItemCount", comment: ""), totalCount)
        }
    }

    func loadThumbnail() async {
        guard let file = playlist.firstTaggableAudioFile() else { return }
        let url = URL(fileURLWithPath: file.path)
        do {
            let asset = AVURLAsset(url: url)
            let metadataList = try await asset.load(.metadata)
            for item in metadataList {
                switch item.commonKey {
                case .commonKeyArtwork?:
                    if let data = try await item.load(.dataValue),
                       let image = UIImage(data: data),
                       let thumb = await image.byPreparingThumbnail(
                        ofSize: CGSize(width: 100.0, height: 100.0)
                       ) {
                        thumbnail = thumb
                        return
                    }
                default: break
                }
            }
        } catch {
            debugPrint("Error loading playlist thumbnail: \(error.localizedDescription)")
        }
    }
}
