//
//  FBPdfFileRow.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2023/09/14.
//

import SwiftUI

struct FBPdfFileRow: View {

    @State var file: FSFile

    var body: some View {
        NavigationLink(value: ViewPath.pdfViewer(file: file)) {
            ListFileRow(file: .constant(file))
                .tint(.primary)
        }
        // WARN: Will crash on iOS 18 if built with Xcode < 26.1
        .navigationLinkIndicatorVisibility(.hidden)
    }
}
