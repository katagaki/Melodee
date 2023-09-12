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
    @EnvironmentObject var fileManager: FilesystemManager
    @EnvironmentObject var mediaPlayer: MediaPlayerManager
    @State var currentDirectory: FSDirectory?
    @State var files: [any FilesystemObject] = []
    @State var state = FBState()

    var body: some View {
        NavigationStack(path: $navigationManager.filesTabPath) {
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
                                case .zip: FBZipFileRow(file: file) { extractZIP(file: file) }
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
            .listStyle(.insetGrouped)
            .safeAreaInset(edge: .bottom) {
                Color.clear
                    .frame(height: 56.0)
            }
            .navigationDestination(for: ViewPath.self, destination: { viewPath in
                switch viewPath {
                case .fileBrowser(let directory): FileBrowserView(currentDirectory: directory)
                case .tagEditorSingle(let file): TagEditorView(files: [file])
                case .tagEditorMultiple(let files): TagEditorView(files: files)
                default: Color.clear
                }
            })
            .refreshable {
                refreshFiles()
            }
            .overlay {
                if files.count == 0 && state.isInitialLoadCompleted {
                    VStack {
                        ListHintOverlay(image: "questionmark.folder",
                                        text: "FileBrowser.Hint")
                    }
                }
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
                            OpenFilesAppButton()
                                .popoverTip(FBNoFilesTip(), arrowEdge: .top)
                        }
                    }
                }
            }
            .alert("Alert.RenameFile.Title", isPresented: $state.isRenamingFile, actions: {
                TextField("Shared.NewFileName", text: $state.newFileName)
                Button("Shared.Change") {
                    if let fileBeingRenamed = state.fileBeingRenamed {
                        fileManager.renameFile(file: fileBeingRenamed, newName: state.newFileName)
                        refreshFiles()
                    }
                }
                .disabled(state.newFileName == "")
                Button("Shared.Cancel", role: .cancel) {
                    state.fileBeingRenamed = nil
                }
            })
            .alert("Alert.RenameFile.Title", isPresented: $state.isRenamingDirectory, actions: {
                TextField("Shared.NewDirectoryName", text: $state.newDirectoryName)
                Button("Shared.Change") {
                    if let directoryBeingRenamed = state.directoryBeingRenamed {
                        fileManager.renameDirectory(directory: directoryBeingRenamed,
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
            },
                   message: {
                Text(verbatim: state.errorText)
            })
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            refreshFiles()
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
    }

    func refreshFiles() {
        withAnimation {
            files = fileManager.files(in: currentDirectory?.path ?? "")
                .sorted(by: { lhs, rhs in
                    lhs.name < rhs.name
                })
                .sorted(by: { lhs, rhs in
                    return lhs is FSDirectory && rhs is FSFile
                })
            state.isInitialLoadCompleted = true
        }
    }

    func extractZIP(file: FSFile) {
        withAnimation(.easeOut.speed(2)) {
            state.isExtractingZIP = true
        }
        fileManager.extractFiles(file: file) {
            state.extractionPercentage =
                Int((fileManager.extractionProgress?.fractionCompleted ?? 0) * 100)
        } onError: { error in
            withAnimation(.easeOut.speed(2)) {
                state.isExtractingZIP = false
                state.errorText = error
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                state.isErrorAlertPresenting = true
            }
        } onCompletion: {
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
