//
//  FBState.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2023/09/12.
//

import Foundation

struct FBState {
    // State handling for display
    var isInitialLoadCompleted: Bool = false

    // State handling for file rename
    var isRenamingFile: Bool = false
    var fileBeingRenamed: FSFile?
    var newFileName: String = ""

    // State handling for directory rename
    var isRenamingDirectory: Bool = false
    var directoryBeingRenamed: FSDirectory?
    var newDirectoryName: String = ""

    // State handling for ZIP extraction
    var isExtractingZIP: Bool = false
    var extractionPercentage: Int = 0
    var isExtractionCancelling: Bool = false
    var isErrorAlertPresenting: Bool = false
    var errorText: String = ""
}
