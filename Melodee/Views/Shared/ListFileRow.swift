//
//  ListFileRow.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2023/09/11.
//

import AVFoundation
import SwiftUI

struct ListFileRow: View {

    @Environment(MediaPlayerManager.self) var mediaPlayer

    @Binding var file: FSFile
    @State var thumbnail: UIImage?
    @State var isThumbnailFetchCompleted: Bool = false

    var body: some View {
        HStack(alignment: .center, spacing: 16.0) {
            if file.extension == "mp3" || file.type == .image,
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
                            .offset(x: 6.0, y: 6.0)
                    }
            } else {
                file.type.icon()
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28.0, height: 28.0)
            }
            VStack(alignment: .leading, spacing: 2.0) {
                Text(file.name)
                    .font(.body)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Text(URL(filePath: file.path).fileSizeString)
                    .font(.caption)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .foregroundStyle(.secondary)
            }
        }
        .task {
            if !isThumbnailFetchCompleted {
                Task.detached {
                    let fileURL: URL = URL(filePath: file.path)
                    if file.extension == "mp3" {
                        NSFileCoordinator().coordinate(readingItemAt: fileURL, error: .none) { url in
                            Task {
                                let albumArt = await albumArt(at: url)
                                withAnimation(.default.speed(2)) {
                                    self.thumbnail = albumArt
                                }
                            }
                        }
                    } else if file.type == .image {
                        NSFileCoordinator().coordinate(readingItemAt: fileURL, error: .none) { url in
                            Task {
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
            let playerItem = AVPlayerItem(url: url)
            let metadataList = try await playerItem.asset.load(.metadata)
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
        return UIImage(named: "Album.Generic")!
    }

}
