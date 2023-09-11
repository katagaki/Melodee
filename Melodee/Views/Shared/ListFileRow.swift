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
        HStack(alignment: .center, spacing: 16.0) {
            Image("AudioFile")
                .resizable()
                .scaledToFit()
                .frame(width: 28.0, height: 28.0)
            Text(file.name)
                .font(.body)
                .lineLimit(1)
                .truncationMode(.middle)
        }
    }

}
