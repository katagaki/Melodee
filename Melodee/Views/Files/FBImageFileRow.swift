//
//  FBImageFileRow.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2023/09/12.
//

import SwiftUI

struct FBImageFileRow: View {

    @EnvironmentObject var navigationManager: NavigationManager
    @State var file: FSFile

    var body: some View {
        Button {
            navigationManager.push(ViewPath.imageViewer(file: file), for: .fileManager)
        } label: {
            ListFileRow(file: .constant(file))
                .tint(.primary)
        }
    }
}
