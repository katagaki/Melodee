@preconcurrency import SFBAudioEngine
import SwiftUI

extension TagEditorView {
    func readAllTagData() async {
        await MainActor.run {
            initialLoadPercentage = 0
        }
        let filesToRead = files
        let result = await Task.detached(priority: .userInitiated) {
            () -> (audioFiles: [FSFile: AudioFile], tagCombined: TagTyped?) in
            debugPrint("Attempting to read tag data for \(filesToRead.count) files...")
            var loadedAudioFiles: [FSFile: AudioFile] = [:]
            var tagCombined: TagTyped?
            let total = filesToRead.count
            var readCount = 0
            for file in filesToRead {
                debugPrint("Attempting to read tag data for file \(file.name)...")
                if let audioFile = AudioFile.read(for: file) {
                    loadedAudioFiles[file] = audioFile
                    if tagCombined == nil {
                        tagCombined = await TagTyped(file, audioFile: audioFile)
                    } else {
                        await tagCombined!.merge(with: file, audioFile: audioFile)
                    }
                }
                readCount += 1
                let percentage = total > 0 ? (readCount * 100) / total : 0
                await MainActor.run {
                    initialLoadPercentage = percentage
                }
            }
            return (loadedAudioFiles, tagCombined)
        }.value

        await MainActor.run {
            audioFiles = result.audioFiles
            if let tagCombined = result.tagCombined {
                debugPrint("Saving tag data")
                tagData = Tag(from: tagCombined)
            }
        }
    }

    func saveAllTagData() async {
        await MainActor.run {
            savePercentage = 0
        }
        let cachedAudioFiles = audioFiles
        let tagSnapshot = tagData
        let total = cachedAudioFiles.count
        guard total > 0 else { return }

        let maxConcurrentSaves = 4
        var savedCount = 0
        await withTaskGroup(of: Bool.self) { group in
            var iterator = cachedAudioFiles.makeIterator()

            func addNext() -> Bool {
                guard let (file, audioFile) = iterator.next() else { return false }
                nonisolated(unsafe) let audioFileRef = audioFile
                group.addTask(priority: .userInitiated) {
                    return audioFileRef.saveTagData(to: file, tagData: tagSnapshot)
                }
                return true
            }

            for _ in 0..<maxConcurrentSaves {
                if !addNext() { break }
            }

            while await group.next() != nil {
                savedCount += 1
                let percentage = (savedCount * 100) / total
                await MainActor.run {
                    savePercentage = percentage
                }
                _ = addNext()
            }
        }
    }

    func changeSaveState(to newState: SaveState) {
        withAnimation(.snappy.speed(2)) {
            saveState = newState
        }
    }
}
