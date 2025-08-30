//
//  FBImageFileRow.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2023/09/12.
//

import SwiftUI

struct FBImageFileRow: View {

    @State var file: FSFile

    var body: some View {
        NavigationLink(value: ViewPath.imageViewer(file: file)) {
            ListFileRow(file: .constant(file))
                .tint(.primary)
        }
        .navigationLinkIndicatorVisibility(.hidden)
    }
}
