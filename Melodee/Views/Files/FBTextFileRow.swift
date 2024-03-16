//
//  FBTextFileRow.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2023/09/14.
//

import SwiftUI

struct FBTextFileRow: View {

    @EnvironmentObject var navigationManager: NavigationManager

    @State var file: FSFile

    var body: some View {
        Button {
            navigationManager.push(ViewPath.textViewer(file: file), for: .fileManager)
        } label: {
            ListFileRow(file: .constant(file))
                .tint(.primary)
        }
    }
}
