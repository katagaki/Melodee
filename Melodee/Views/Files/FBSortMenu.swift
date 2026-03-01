//
//  FBSortMenu.swift
//  Melodee
//
//  Created by Claude on 2026/03/01.
//

import SwiftUI

struct FBSortMenu: View {

    @Binding var sortOption: SortOption
    @Binding var sortOrder: SortOrder

    var body: some View {
        Menu {
            Picker("Sort.SortBy", selection: $sortOption) {
                Label("Sort.FileName", systemImage: "doc")
                    .tag(SortOption.fileName)
                Label("Sort.TrackTitle", systemImage: "music.note")
                    .tag(SortOption.trackTitle)
                Label("Sort.TrackNumber", systemImage: "number")
                    .tag(SortOption.trackNumber)
                Label("Sort.AlbumName", systemImage: "square.stack")
                    .tag(SortOption.albumName)
                Label("Sort.ArtistName", systemImage: "music.mic")
                    .tag(SortOption.artistName)
            }
            Picker("Sort.Order", selection: $sortOrder) {
                Label("Sort.Ascending", systemImage: "arrow.up")
                    .tag(SortOrder.ascending)
                Label("Sort.Descending", systemImage: "arrow.down")
                    .tag(SortOrder.descending)
            }
        } label: {
            Label("Sort.Title", systemImage: "arrow.up.arrow.down")
        }
        .menuActionDismissBehavior(.disabled)
    }
}
