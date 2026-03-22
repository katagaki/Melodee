//
//  CreatePlaylistSheet.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2024/03/16.
//

@preconcurrency import AVFoundation
import SwiftUI

struct CreatePlaylistSheet: View {

    @Environment(\.dismiss) var dismiss

    var audioFiles: [FSFile]
    var directoryURL: URL
    var onCreated: () -> Void

    @State var playlistName: String = ""
    @State var selectedFiles: Set<String> = []
    @State var thumbnail: UIImage?
    @FocusState var isNameFieldFocused: Bool

    var body: some View {
        NavigationStack {
            List {
                // MARK: - Header
                Section {
                    VStack(spacing: 12.0) {
                        // Album art thumbnail
                        Group {
                            if let thumbnail {
                                Image(uiImage: thumbnail)
                                    .resizable()
                                    .scaledToFill()
                            } else {
                                Image("Album.Generic")
                                    .resizable()
                                    .scaledToFill()
                            }
                        }
                        .frame(width: 140.0, height: 140.0)
                        .clipShape(RoundedRectangle(cornerRadius: 12.0))
                        .shadow(radius: 4.0)

                        // Name field
                        TextField("Playlists.PlaylistName", text: $playlistName)
                            .font(.title2.bold())
                            .multilineTextAlignment(.center)
                            .focused($isNameFieldFocused)
                    }
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .padding(.vertical, 8.0)
                }

                // MARK: - Song list
                Section {
                    Button {
                        if selectedFiles.count == audioFiles.count {
                            selectedFiles.removeAll()
                        } else {
                            selectedFiles = Set(audioFiles.map(\.path))
                        }
                    } label: {
                        HStack {
                            Image(systemName: selectedFiles.count == audioFiles.count
                                  ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(selectedFiles.count == audioFiles.count
                                                 ? .accent : .secondary)
                                .imageScale(.large)
                            Text("Playlists.SelectAll")
                                .foregroundStyle(.primary)
                            Spacer()
                            Text("\(selectedFiles.count)/\(audioFiles.count)")
                                .foregroundStyle(.secondary)
                                .font(.subheadline)
                        }
                    }
                    .listRowBackground(Color.clear)

                    ForEach(audioFiles, id: \.path) { file in
                        Button {
                            toggleSelection(file)
                        } label: {
                            HStack(spacing: 12.0) {
                                Image(systemName: selectedFiles.contains(file.path)
                                      ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(selectedFiles.contains(file.path)
                                                     ? .accent : .secondary)
                                    .imageScale(.large)
                                VStack(alignment: .leading, spacing: 2.0) {
                                    Text(file.name)
                                        .font(.body)
                                        .foregroundStyle(.primary)
                                        .lineLimit(1)
                                    Text("\(file.name).\(file.extension)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                                Spacer()
                            }
                        }
                        .listRowBackground(Color.clear)
                    }
                } header: {
                    Text("Playlists.Songs")
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(
                .linearGradient(
                    colors: [.backgroundGradientTop, .backgroundGradientBottom],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationTitle("Playlists.CreatePlaylist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Shared.Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Shared.Save") {
                        createPlaylist()
                        dismiss()
                    }
                    .bold()
                    .disabled(playlistName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                              || selectedFiles.isEmpty)
                }
            }
            .onAppear {
                // Select all by default
                selectedFiles = Set(audioFiles.map(\.path))
                isNameFieldFocused = true
            }
            .task {
                await loadThumbnail()
            }
        }
    }

    func toggleSelection(_ file: FSFile) {
        if selectedFiles.contains(file.path) {
            selectedFiles.remove(file.path)
        } else {
            selectedFiles.insert(file.path)
        }
    }

    func createPlaylist() {
        let trimmedName = playlistName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        let selected = audioFiles.filter { selectedFiles.contains($0.path) }
        _ = PlaylistManager.create(name: trimmedName, in: directoryURL, audioFiles: selected)
        onCreated()
    }

    func loadThumbnail() async {
        guard let firstAudio = audioFiles.first(where: { $0.isTaggableAudio() }) else { return }
        let url = URL(fileURLWithPath: firstAudio.path)
        do {
            let asset = AVURLAsset(url: url)
            let metadataList = try await asset.load(.metadata)
            for item in metadataList {
                switch item.commonKey {
                case .commonKeyArtwork?:
                    if let data = try await item.load(.dataValue),
                       let image = UIImage(data: data),
                       let thumb = await image.byPreparingThumbnail(
                        ofSize: CGSize(width: 280.0, height: 280.0)
                       ) {
                        thumbnail = thumb
                        return
                    }
                default: break
                }
            }
        } catch {
            debugPrint("Error loading thumbnail: \(error.localizedDescription)")
        }
    }
}
