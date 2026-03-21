//
//  PlaylistsView.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2024/03/16.
//

import SwiftData
import SwiftUI

struct PlaylistsView: View {

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Playlist.name) private var playlists: [Playlist]

    @State var isCreatingPlaylist: Bool = false
    @State var newPlaylistName: String = ""

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
                    Button {
                        newPlaylistName = ""
                        isCreatingPlaylist = true
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
            .hasFileBrowserNavigationDestinations()
        }
    }

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
}
