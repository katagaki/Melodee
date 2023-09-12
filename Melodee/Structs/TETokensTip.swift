//
//  TETokensTip.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2023/09/12.
//

import Foundation
import TipKit

struct TETokensTip: Tip {
    var title: Text {
        Text("TagEditor.Tip.Tokens.Title")
    }
    var message: Text? {
        Text("TagEditor.Tip.Tokens.Text")
    }
    var image: Image? {
        Image(systemName: "info.circle.fill")
    }
}
