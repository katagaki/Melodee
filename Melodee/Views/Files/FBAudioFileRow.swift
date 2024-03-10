//
//  FBAudioFileRow.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2023/09/12.
//

import SwiftUI

struct FBAudioFileRow: View {

    @Environment(MediaPlayerManager.self) var mediaPlayer

    @State var file: FSFile

    var body: some View {
        Button {
            mediaPlayer.playImmediately(file)
        } label: {
            ListFileRow(file: .constant(file))
                .tint(.primary)
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
                withAnimation(.default.speed(2)) {
                    mediaPlayer.queueNext(file: file)
                }
            } label: {
                Label("Shared.Play.Next",
                      systemImage: "text.line.first.and.arrowtriangle.forward")
            }
            .tint(.purple)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button {
                withAnimation(.default.speed(2)) {
                    mediaPlayer.queueLast(file: file)
                }
            } label: {
                Label("Shared.Play.Last",
                      systemImage: "text.line.last.and.arrowtriangle.forward")
            }
            .tint(.orange)
        }
    }
}
