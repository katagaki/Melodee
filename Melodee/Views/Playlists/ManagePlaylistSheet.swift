//
//  ManagePlaylistSheet.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2024/03/16.
//

@preconcurrency import AVFoundation
import SwiftUI

struct ManagePlaylistSheet: View {

    @Environment(\.dismiss) var dismiss

    var scopeRootURL: URL
    var playlistDirectoryURL: URL
    var fileManager: FilesystemManager
    var existingFiles: [PlaylistFile]
    var onSave: ([PlaylistFile]) -> Void

    @State var allAudioFiles: [FSFile] = []
    @State var selectedPaths: Set<String> = []
    @State var isLoading: Bool = true

    var body: some View {
        NavigationStack {
            List {
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
                        .listRowSeparator(.hidden, edges: .all)
                        .listRowBackground(Color.clear)
                    }
                } else {
                    Section {
                        Button {
                            if selectedPaths.count == allAudioFiles.count {
                                selectedPaths.removeAll()
                            } else {
                                selectedPaths = Set(allAudioFiles.map(\.path))
                            }
                        } label: {
                            HStack {
                                Image(systemName: selectedPaths.count == allAudioFiles.count
                                      ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(selectedPaths.count == allAudioFiles.count
                                                     ? .accent : .secondary)
                                    .imageScale(.large)
                                Text("Playlists.SelectAll")
                                    .foregroundStyle(.primary)
                                Spacer()
                                Text("\(selectedPaths.count)/\(allAudioFiles.count)")
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
                                    Image(systemName: selectedPaths.contains(file.path)
                                          ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(selectedPaths.contains(file.path)
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
            .navigationTitle("Playlists.Manage")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .cancel) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(role: .confirm) {
                        saveChanges()
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadAllAudioFiles()
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

        // Pre-select files that are already in the playlist
        for existing in existingFiles {
            let resolvedURL = playlistDirectoryURL.appendingPathComponent(existing.relativePath)
            let resolvedPath = resolvedURL.path(percentEncoded: false)
            if allAudioFiles.contains(where: { $0.path == resolvedPath }) {
                selectedPaths.insert(resolvedPath)
            }
        }

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
        if selectedPaths.contains(file.path) {
            selectedPaths.remove(file.path)
        } else {
            selectedPaths.insert(file.path)
        }
    }

    func saveChanges() {
        let baseURL = playlistDirectoryURL
        let selected = allAudioFiles.filter { selectedPaths.contains($0.path) }
        let updatedFiles = selected.compactMap { file -> PlaylistFile? in
            guard let relativePath = PlaylistManager.relativePath(
                from: baseURL,
                to: URL(fileURLWithPath: file.path)
            ) else { return nil }
            return PlaylistFile(relativePath: relativePath)
        }
        onSave(updatedFiles)
    }
}
