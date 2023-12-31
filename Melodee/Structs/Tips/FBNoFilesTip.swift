//
//  FBNoFilesTip.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2023/09/11.
//

import Foundation
import TipKit

struct FBNoFilesTip: Tip {
    var title: Text {
        Text("FileBrowser.Tip.NoFiles.Title")
    }
    var message: Text? {
        Text("FileBrowser.Tip.NoFiles.Text")
    }
    var image: Image? {
        Image(systemName: "questionmark.folder.fill")
    }
}
