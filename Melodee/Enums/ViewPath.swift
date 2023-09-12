//
//  ViewPath.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2023/09/11.
//

import Foundation

enum ViewPath: Hashable {
    case fileBrowser(directory: FSDirectory)
    case tagEditorSingle(file: FSFile)
    case tagEditorMultiple(files: [FSFile])
    case moreAttributions
}
