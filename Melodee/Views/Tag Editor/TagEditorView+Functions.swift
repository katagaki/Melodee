//
//  TagEditorView+Functions.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2026/03/01.
//

import SwiftUI
import SwiftTagger

extension TagEditorView {
    func readAllTagData() async {
        debugPrint("Attempting to read tag data for \(files.count) files...")
        // Check for common tag data betwen all files
        var tagCombined: TagTyped?
        initialLoadPercentage = 0
        for file in files {
            debugPrint("Attempting to read tag data for file \(file.name)...")
            do {
                let fileURL = URL(fileURLWithPath: file.path)
                let audioFile = try AudioFile(location: fileURL)
                audioFiles.updateValue(audioFile, forKey: file)

                if tagCombined == nil {
                    tagCombined = await TagTyped(file, audioFile: audioFile)
                } else {
                    await tagCombined!.merge(with: file, audioFile: audioFile)
                }
            } catch {
                debugPrint("Error occurred while reading tags: \n\(error.localizedDescription)")
                // Try to create new tag
                if let newAudioFile = AudioFile.newTag(for: file) {
                    audioFiles.updateValue(newAudioFile, forKey: file)
                }
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
        _ = await withTaskGroup(of: Bool.self, returning: [Bool].self) { group in
            for (file, var audioFile) in audioFiles {
                group.addTask {
                    return await audioFile.saveTagData(to: file, tagData: tagData)
                }
            }
            var saveStates: [Bool] = []
            for await result in group {
                DispatchQueue.main.async {
                    savePercentage += 100 / audioFiles.count
                }
                saveStates.append(result)
            }
            return saveStates
        }
    }

    func changeSaveState(to newState: SaveState) {
        withAnimation(.snappy.speed(2)) {
            saveState = newState
        }
    }
}
