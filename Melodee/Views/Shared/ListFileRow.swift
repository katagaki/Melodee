//
//  ListFileRow.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2023/09/11.
//

import SwiftUI

struct ListFileRow: View {

    @EnvironmentObject var mediaPlayer: MediaPlayerManager

    @Binding var file: FSFile

    var body: some View {
        VStack(alignment: .leading, spacing: 8.0) {
            Text(file.name)
                .font(.body)
                .lineLimit(1)
                .truncationMode(.middle)
            HStack(alignment: .center, spacing: 8.0) {
                ActionButton(text: "Shared.Play",
                             icon: "play.fill",
                             isPrimary: true) {
                    mediaPlayer.play(file: file)
                }
                ActionButton(text: "Shared.Play.Next", icon: "text.line.first.and.arrowtriangle.forward") {
                    withAnimation(.default.speed(2)) {
                        mediaPlayer.playNext(file: file)
                    }
                }
                ActionButton(text: "Shared.Play.Last", icon: "text.line.last.and.arrowtriangle.forward") {
                    withAnimation(.default.speed(2)) {
                        mediaPlayer.playLast(file: file)
                    }
                }
            }
        }
    }

}
