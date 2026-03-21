//
//  PlaylistsView.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2024/03/16.
//

import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct PlaylistsView: View {

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Playlist.name) private var playlists: [Playlist]

    @State var isCreatingPlaylist: Bool = false
    @State var newPlaylistName: String = ""
    @State var isImportingPlaylist: Bool = false
    @State var importError: String?
    @State var isShowingImportError: Bool = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(playlists) { playlist in
                        NavigationLink(value: playlist.persistentModelID) {
                            PlaylistRow(playlist: playlist)
                        }
                        .listRowBackground(Color.clear)
                    }
                    .onDelete(perform: deletePlaylists)
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
            .navigationTitle("ViewTitle.Playlists")
            .navigationDestination(for: PersistentIdentifier.self) { playlistID in
                if let playlist = playlists.first(where: { $0.persistentModelID == playlistID }) {
                    PlaylistDetailView(playlist: playlist)
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            newPlaylistName = ""
                            isCreatingPlaylist = true
                        } label: {
                            Label("Playlists.CreatePlaylist", systemImage: "plus")
                        }
                        Button {
                            isImportingPlaylist = true
                        } label: {
                            Label("Playlists.Import", systemImage: "square.and.arrow.down")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .overlay {
                if playlists.isEmpty {
                    ContentUnavailableView {
                        Label("Playlists.Empty.Title", systemImage: "music.note.list")
                    } description: {
                        Text("Playlists.Empty.Description")
                    } actions: {
                        Button {
                            newPlaylistName = ""
                            isCreatingPlaylist = true
                        } label: {
                            Text("Playlists.CreatePlaylist")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            .alert("Playlists.CreatePlaylist", isPresented: $isCreatingPlaylist) {
                TextField("Playlists.PlaylistName", text: $newPlaylistName)
                Button("Shared.Cancel", role: .cancel) { }
                Button("Shared.Create") {
                    createPlaylist()
                }
            }
            .alert("Playlists.Import.Error", isPresented: $isShowingImportError) {
                Button("Shared.OK", role: .cancel) { }
            } message: {
                if let importError {
                    Text(importError)
                }
            }
            .sheet(isPresented: $isImportingPlaylist) {
                DocumentPicker(
                    allowedUTIs: PlaylistsView.importUTTypes,
                    onDocumentPicked: { url in
                        importPlaylist(from: url)
                    }
                )
                .ignoresSafeArea(edges: [.bottom])
            }
            .hasFileBrowserNavigationDestinations()
        }
    }

    static let importUTTypes: [UTType] = {
        var types: [UTType] = [.json]
        if let m3u8 = UTType(filenameExtension: "m3u8") {
            types.append(m3u8)
        }
        if let m3u = UTType(filenameExtension: "m3u") {
            types.append(m3u)
        }
        return types
    }()

    func createPlaylist() {
        let trimmedName = newPlaylistName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        let playlist = Playlist(name: trimmedName)
        modelContext.insert(playlist)
    }

    func deletePlaylists(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(playlists[index])
        }
    }

    func importPlaylist(from url: URL) {
        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing { url.stopAccessingSecurityScopedResource() }
        }

        let ext = url.pathExtension.lowercased()
        let baseURL = url.deletingLastPathComponent()

        if ext == "json" {
            importJSONPlaylist(from: url, baseURL: baseURL)
        } else if ext == "m3u8" || ext == "m3u" {
            importM3U8Playlist(from: url, baseURL: baseURL)
        }
    }

    func importJSONPlaylist(from url: URL, baseURL: URL) {
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let playlistJSON = try decoder.decode(PlaylistJSON.self, from: data)
            let playlist = Playlist(name: playlistJSON.name)
            modelContext.insert(playlist)
            playlist.importFromJSON(playlistJSON, baseURL: baseURL)
        } catch {
            importError = error.localizedDescription
            isShowingImportError = true
        }
    }

    func importM3U8Playlist(from url: URL, baseURL: URL) {
        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            let parsed = Playlist.fromM3U8(content: content, baseURL: baseURL)
            let playlistName = parsed.name
                ?? url.deletingPathExtension().lastPathComponent
            let playlist = Playlist(name: playlistName)
            modelContext.insert(playlist)

            for relativePath in parsed.relativePaths {
                let fileURL = baseURL.appendingPathComponent(relativePath)
                if FileManager.default.fileExists(atPath: fileURL.path(percentEncoded: false)) {
                    try playlist.addFile(url: fileURL)
                }
            }
        } catch {
            importError = error.localizedDescription
            isShowingImportError = true
        }
    }
}
