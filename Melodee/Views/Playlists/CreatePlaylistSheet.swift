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

    var scopeRootURL: URL
    var saveDirectoryURL: URL
    var fileManager: FilesystemManager
    var onCreated: () -> Void

    @State var playlistName: String = ""
    @State var allAudioFiles: [FSFile] = []
    @State var selectedFiles: Set<String> = []
    @State var thumbnail: UIImage?
    @State var isLoading: Bool = true
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
                if isLoading {
                    Section {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                        .listRowBackground(Color.clear)
                    }
                } else if allAudioFiles.isEmpty {
                    Section {
                        ContentUnavailableView {
                            Label("Playlists.NoAudioFiles.Title", systemImage: "music.note")
                        } description: {
                            Text("Playlists.NoAudioFiles.Description")
                        }
                        .listRowBackground(Color.clear)
                    }
                } else {
                    Section {
                        Button {
                            if selectedFiles.count == allAudioFiles.count {
                                selectedFiles.removeAll()
                            } else {
                                selectedFiles = Set(allAudioFiles.map(\.path))
                            }
                        } label: {
                            HStack {
                                Image(systemName: selectedFiles.count == allAudioFiles.count
                                      ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(selectedFiles.count == allAudioFiles.count
                                                     ? .accent : .secondary)
                                    .imageScale(.large)
                                Text("Playlists.SelectAll")
                                    .foregroundStyle(.primary)
                                Spacer()
                                Text("\(selectedFiles.count)/\(allAudioFiles.count)")
                                    .foregroundStyle(.secondary)
                                    .font(.subheadline)
                            }
                        }
                        .listRowBackground(Color.clear)

                        ForEach(allAudioFiles, id: \.path) { file in
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
                                        Text(relativeDisplayPath(for: file))
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
                isNameFieldFocused = true
                loadAllAudioFiles()
            }
            .task {
                await loadThumbnail()
            }
        }
    }

    func loadAllAudioFiles() {
        let allFiles = fileManager.files(in: scopeRootURL)
        var audioFiles: [FSFile] = []
        collectAudioFiles(from: allFiles, into: &audioFiles)
        allAudioFiles = audioFiles.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
        selectedFiles = Set(allAudioFiles.map(\.path))
        isLoading = false
    }

    func collectAudioFiles(from objects: [any FilesystemObject], into result: inout [FSFile]) {
        for object in objects {
            if let file = object as? FSFile, file.type == .audio {
                result.append(file)
            } else if let directory = object as? FSDirectory {
                collectAudioFiles(from: directory.files, into: &result)
            }
        }
    }

    /// Display path relative to scope root (e.g. "subfolder/song.mp3")
    func relativeDisplayPath(for file: FSFile) -> String {
        let filePath = file.path
        let rootPath = scopeRootURL.path(percentEncoded: false)
        if filePath.hasPrefix(rootPath) {
            var relative = String(filePath.dropFirst(rootPath.count))
            if relative.hasPrefix("/") {
                relative = String(relative.dropFirst())
            }
            return relative
        }
        return "\(file.name).\(file.extension)"
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

        let selected = allAudioFiles.filter { selectedFiles.contains($0.path) }
        _ = PlaylistManager.create(
            name: trimmedName,
            in: saveDirectoryURL,
            audioFiles: selected
        )
        onCreated()
    }

    func loadThumbnail() async {
        // Wait for files to load
        while isLoading {
            try? await Task.sleep(for: .milliseconds(100))
        }
        guard let firstAudio = allAudioFiles.first(where: { $0.isTaggableAudio() }) else { return }
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
