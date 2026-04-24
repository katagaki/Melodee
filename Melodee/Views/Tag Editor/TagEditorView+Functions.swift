//
//  TagEditorView+Functions.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2026/03/01.
//

import SFBAudioEngine
import SwiftUI

extension TagEditorView {
    func readAllTagData() async {
        debugPrint("Attempting to read tag data for \(files.count) files...")
        // Check for common tag data betwen all files
        var tagCombined: TagTyped?
        initialLoadPercentage = 0
        for file in files {
            debugPrint("Attempting to read tag data for file \(file.name)...")
            guard let audioFile = AudioFile.read(for: file) else {
                initialLoadPercentage += 100 / files.count
                continue
            }
            audioFiles.updateValue(audioFile, forKey: file)

            nonisolated(unsafe) let audioFileRef = audioFile
            if tagCombined == nil {
                tagCombined = await TagTyped(file, audioFile: audioFileRef)
            } else {
                await tagCombined!.merge(with: file, audioFile: audioFileRef)
            }
            initialLoadPercentage += 100 / files.count
        }
        // Load data into view
        if let tagCombined {
            debugPrint("Saving tag data")
            tagData = Tag(from: tagCombined)
        }
    }

    func saveAllTagData() async {
        savePercentage = 0
        let tagDataCopy = tagData
        let audioFilesCopy = audioFiles
        let totalCount = audioFilesCopy.count
        for (file, audioFile) in audioFilesCopy {
            _ = audioFile.saveTagData(to: file, tagData: tagDataCopy)
            savePercentage += 100 / totalCount
        }
    }

    func changeSaveState(to newState: SaveState) {
        withAnimation(.snappy.speed(2)) {
            saveState = newState
        }
    }
}
