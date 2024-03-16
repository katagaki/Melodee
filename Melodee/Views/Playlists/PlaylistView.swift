//
//  PlaylistView.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2024/03/16.
//

import SwiftUI

struct PlaylistView: View {

    @Environment(PlaylistManager.self) var playlistManager

    @State var isSelectingFileToAdd: Bool = false
    @State var playlistIDToAddFileTo: String = ""
    @State var playlist: Playlist

    var body: some View {
        List {
            ForEach(playlist.playlistItems(), id: \.id) { playlistItem in
                ListFileRow(file: .constant(FSFile(name: playlistItem.path,
                                                   extension: "mp3",
                                                   path: playlistItem.path,
                                                   type: .audio)))
            }
            Button {
                playlistIDToAddFileTo = playlist.id
                isSelectingFileToAdd = true
            } label: {
                Label("Playlists.AddFiles", systemImage: "plus")
            }
        }
        .sheet(isPresented: $isSelectingFileToAdd) {
            DocumentPicker(allowedUTIs: [.audio], onDocumentPicked: { url in
                let isAccessSuccessful = url.startAccessingSecurityScopedResource()
                if isAccessSuccessful {
                    playlistManager.add(url.path(percentEncoded: false), to: playlistIDToAddFileTo)
                    if let playlist = playlistManager.playlists.first(where: { $0.id == playlist.id }) {
                        self.playlist = playlist
                    }
                    playlistIDToAddFileTo = ""
                } else {
                    url.stopAccessingSecurityScopedResource()
                }
            })
            .ignoresSafeArea(edges: [.bottom])
        }
    }
}
