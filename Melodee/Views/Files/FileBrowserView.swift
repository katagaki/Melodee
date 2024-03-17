//
//  FileBrowserView.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2023/09/11.
//

import SwiftUI
import TipKit

struct FileBrowserView: View {

    @EnvironmentObject var navigationManager: NavigationManager
    @Environment(FilesystemManager.self) var fileManager
    @Environment(MediaPlayerManager.self) var mediaPlayer

    @State var currentDirectory: FSDirectory?
    @State var files: [any FilesystemObject] = []
    @State var state = FBState()
    @State var isSelectingExternalDirectory = false

    var body: some View {
        List {
            FBPlaybackSection(currentDirectory: $currentDirectory,
                                 files: $files)
            Section {
                ForEach($files, id: \.path) { $file in
                    Group {
                        if let directory = file as? FSDirectory {
                            FBDirectoryRow(directory: directory)
                        } else if let file = file as? FSFile {
                            switch file.type {
                            case .audio: FBAudioFileRow(file: file)
                            case .image: FBImageFileRow(file: file)
                            case .text: FBTextFileRow(file: file)
                            case .pdf: FBPdfFileRow(file: file)
                            case .zip: FBZipFileRow(file: file) { extractZIP(file: file) }
                            default: ListFileRow(file: .constant(file))
                            }
                        }
                    }
                    .contextMenu {
                        FBContextMenu(state: $state, file: file) {
                            if let file = file as? FSFile {
                                extractZIP(file: file)
                            }
                        }
                    }
                }
            }
            if folderContainsEditableMP3s() {
                FBTagSection(files: $files)
            }
        }
        .listStyle(.plain)
        .overlay {
            if files.count == 0 && currentDirectory == nil {
                TipView(FBNoFilesTip())
                    .padding(20.0)
            } else if files.count == 0 && state.isInitialLoadCompleted {
                ContentUnavailableView("FileBrowser.Hint", systemImage: "questionmark.folder")
                    .font(.body)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0.0) {
            Color.clear
                .frame(height: 62.0)
        }
        .refreshable {
            refreshFiles()
        }
        .overlay {
            if state.isExtractingZIP {
                ProgressAlert(title: "Alert.ExtractingZIP.Title",
                              message: "Alert.ExtractingZIP.Text",
                              percentage: $state.extractionPercentage) {
                    withAnimation(.easeOut.speed(2)) {
                        state.isExtractionCancelling = true
                        fileManager.extractionProgress?.cancel()
                        state.extractionPercentage = 0
                        state.isExtractingZIP = false
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack {
                    if currentDirectory == nil {
                        StorageLocationSelector(isSelectingExternalDirectory: $isSelectingExternalDirectory)
                    }
                }
            }
        }
        .alert("Alert.RenameFile.Title", isPresented: $state.isRenamingFile, actions: {
            TextField("Shared.NewFileName", text: $state.newFileName)
            Button("Shared.Change") {
                if let fileBeingRenamed = state.fileBeingRenamed {
                    fileManager.rename(file: fileBeingRenamed, newName: state.newFileName)
                    refreshFiles()
                }
            }
            .disabled(state.newFileName == "")
            Button("Shared.Cancel", role: .cancel) {
                state.fileBeingRenamed = nil
            }
        })
        .alert("Alert.RenameDirectory.Title", isPresented: $state.isRenamingDirectory, actions: {
            TextField("Shared.NewDirectoryName", text: $state.newDirectoryName)
            Button("Shared.Change") {
                if let directoryBeingRenamed = state.directoryBeingRenamed {
                    fileManager.rename(directory: directoryBeingRenamed,
                                                newName: state.newDirectoryName)
                    refreshFiles()
                }
            }
            .disabled(state.newDirectoryName == "")
            Button("Shared.Cancel", role: .cancel) {
                state.directoryBeingRenamed = nil
            }
        })
        .alert("Alert.ExtractingZIP.Error.Title", isPresented: $state.isErrorAlertPresenting, actions: {
            Button("Shared.OK", role: .cancel) { }
        }, message: {
            Text(verbatim: state.errorText)
        })
        .alert("Alert.DeleteFile.Title", isPresented: $state.isDeletingFileOrDirectory, actions: {
            Button("Shared.Yes", role: .destructive) {
                if let fileOrDirectoryBeingDeleted = state.fileOrDirectoryBeingDeleted {
                    fileManager.delete(fileOrDirectoryBeingDeleted)
                    refreshFiles()
                }
            }
            Button("Shared.No", role: .cancel) {
                state.fileOrDirectoryBeingDeleted = nil
            }
        }, message: {
            Text(NSLocalizedString("Alert.DeleteFile.Text", comment: "")
                .replacingOccurrences(of: "%1", with: state.fileOrDirectoryBeingDeleted?.name ?? ""))
        })
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if !state.isInitialLoadCompleted {
                refreshFiles()
            }
        }
        .onChange(of: state.fileBeingRenamed) { _, newValue in
            if let fileBeingRenamed = newValue {
                state.newFileName = fileBeingRenamed.name
            } else {
                state.newFileName = ""
            }
        }
        .onChange(of: state.directoryBeingRenamed) { _, newValue in
            if let directoryBeingRenamed = newValue {
                state.newDirectoryName = directoryBeingRenamed.name
            } else {
                state.newDirectoryName = ""
            }
        }
        .onChange(of: fileManager.storageLocation) { _, newValue in
            switch newValue {
            case .local:
                fileManager.directory = fileManager.documentsDirectoryURL
            case .cloud:
                fileManager.directory = fileManager.cloudDocumentsDirectoryURL
            case .external:
                debugPrint("DocumentPicker's responsibility has been fulfilled")
            }
            refreshFiles()
        }
    }

    func refreshFiles() {
        let filesStaged = fileManager.files(in: URL(string: currentDirectory?.path ?? ""))
            .sorted(by: { lhs, rhs in
                lhs.name < rhs.name
            })
        var filesCombined: [any FilesystemObject] = filesStaged.filter({ $0 is FSDirectory })
        let filesOnly: [any FilesystemObject] = filesStaged.filter({ $0 is FSFile })
            .sorted { lhs, rhs in
                if let lhs = lhs as? FSFile, let rhs = rhs as? FSFile {
                    return lhs.type.rawValue < rhs.type.rawValue
                }
                return false
            }
        filesCombined.append(contentsOf: filesOnly)
        withAnimation {
            self.files = filesCombined
            state.isInitialLoadCompleted = true
        }
    }

    func extractZIP(file: FSFile) {
        withAnimation(.easeOut.speed(2)) {
            state.isExtractingZIP = true
        }
        UIApplication.shared.isIdleTimerDisabled = true
        fileManager.extractFiles(file: file) {
            state.extractionPercentage =
                Int((fileManager.extractionProgress?.fractionCompleted ?? 0) * 100)
        } onError: { error in
            UIApplication.shared.isIdleTimerDisabled = false
            withAnimation(.easeOut.speed(2)) {
                state.isExtractingZIP = false
                state.errorText = error
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                state.isErrorAlertPresenting = true
            }
        } onCompletion: {
            UIApplication.shared.isIdleTimerDisabled = false
            withAnimation(.easeOut.speed(2)) {
                state.isExtractingZIP = false
            }
            refreshFiles()
        }
    }

    func folderContainsPlayableAudio() -> Bool {
        for file in files {
            if let file = file as? FSFile, file.type == .audio {
                return true
            }
        }
        return false
    }

    func folderContainsEditableMP3s() -> Bool {
        for file in files {
            if let file = file as? FSFile, file.extension == "mp3" {
                return true
            }
        }
        return false
    }

}
