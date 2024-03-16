//
//  PlaylistsView.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2024/03/10.
//

import Komponents
import SwiftUI

struct PlaylistsView: View {

    @Environment(PlaylistManager.self) var playlistManager

    @State var isCreatingPlaylist: Bool = false
    @State var newPlaylistName: String = ""

    var body: some View {
        @Bindable var playlistManager = playlistManager
        NavigationStack {
            List(playlistManager.playlists, id: \.id) { playlist in
                NavigationLink {
                    PlaylistView(playlist: playlist)
                } label: {
                    ListFolderRow(name: playlist.name)
                }
            }
            .navigationTitle("ViewTitle.Playlists")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isCreatingPlaylist = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .alert("Alert.CreatePlaylist.Title", isPresented: $isCreatingPlaylist, actions: {
                TextField("Shared.NewPlaylistName", text: $newPlaylistName)
                Button("Shared.Create") {
                    isCreatingPlaylist = false
                }
                .disabled(newPlaylistName == "")
                Button("Shared.Cancel", role: .cancel) {
                    newPlaylistName = ""
                }
            })
            .onChange(of: isCreatingPlaylist) { oldValue, newValue in
                if oldValue && !newValue {
                    if newPlaylistName != "" {
                        playlistManager.create(newPlaylistName)
                        newPlaylistName = ""
                    }
                }
            }
        }
    }
}
