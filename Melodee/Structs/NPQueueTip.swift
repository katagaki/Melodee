//
//  NPQueueTip.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2023/09/12.
//

import Foundation
import TipKit

struct NPQueueTip: Tip {
    var title: Text {
        Text("NowPlaying.Tip.Queue.Title")
    }
    var message: Text? {
        Text("NowPlaying.Tip.Queue.Text")
    }
    var image: Image? {
        Image(systemName: "text.line.last.and.arrowtriangle.forward")
    }
}
