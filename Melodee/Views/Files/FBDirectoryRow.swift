//
//  FBDirectoryRow.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2023/09/12.
//

import SwiftUI

struct FBDirectoryRow: View {

    @State var directory: FSDirectory
    var storageLocation: StorageLocation

    var body: some View {
        NavigationLink(value: ViewPath.fileBrowser(directory: directory, storageLocation: storageLocation)) {
            ListFolderRow(name: directory.name)
        }
    }
}
