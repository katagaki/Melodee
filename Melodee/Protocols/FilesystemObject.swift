//
//  FilesystemObject.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2023/09/11.
//

import Foundation

protocol FilesystemObject: Hashable {
    var name: String { get set }
    var path: String { get set }
}
