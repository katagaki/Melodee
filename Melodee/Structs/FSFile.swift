//
//  FSFile.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2023/09/11.
//

import Foundation
import SwiftUI

struct FSFile: FilesystemObject {

    var name: String
    var path: String
    var playbackQueueID: String = ""

    func hash(into hasher: inout Hasher) {
        hasher.combine(path)
    }

}
