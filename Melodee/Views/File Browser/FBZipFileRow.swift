//
//  FBZipFileRow.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2023/09/12.
//

import SwiftUI

struct FBZipFileRow: View {

    @EnvironmentObject var fileManager: FilesystemManager
    @State var file: FSFile
    @State var action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            ListFileRow(file: .constant(file))
                .tint(.primary)
        }
    }
}
