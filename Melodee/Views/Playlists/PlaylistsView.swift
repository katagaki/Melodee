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

    var body: some View {
        @Bindable var playlistManager = playlistManager
        NavigationStack {
            List($playlistManager.playlists, id: \.id, editActions: [.all]) { $playlist in
                Section {
                    ForEach(playlist.items.sorted(by: { $0.order < $1.order })) { item in
                        Text(item.path)
                    }
                } header: {
                    ListSectionHeader(text: playlist.name)
                        .font(.body)
                }
            }
            .navigationTitle("ViewTitle.Playlists")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        playlistManager.create(UUID().uuidString)
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }
}
