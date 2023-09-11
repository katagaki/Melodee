//
//  FileBrowserQueueTip.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2023/09/12.
//

import Foundation
import TipKit

struct FileBrowserQueueTip: Tip {
    var title: Text {
        Text("FileBrowser.Tip.Queue.Title")
    }
    var message: Text? {
        Text("FileBrowser.Tip.Queue.Text")
    }
    var image: Image? {
        Image(systemName: "text.line.last.and.arrowtriangle.forward")
    }
}
