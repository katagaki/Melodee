//
//  FolderView.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2023/09/11.
//

import Komponents
import SwiftUI
import TipKit

struct FolderView: View {

    @State var fileManager: FilesystemManager
    @Environment(MediaPlayerManager.self) var mediaPlayer

    @State var currentDirectory: FSDirectory?
    @State var files: [any FilesystemObject] = []
    @State var state = FBState()
    @State var isSelectingExternalDirectory = false
    @State var storageLocation: StorageLocation = .local

    var overrideStorageLocation: StorageLocation?

    init(
        currentDirectory: FSDirectory? = nil,
        overrideStorageLocation: StorageLocation? = nil,
        fileManager: FilesystemManager? = nil
    ) {
        self.currentDirectory = currentDirectory
        self.overrideStorageLocation = overrideStorageLocation
        self._fileManager = State(initialValue: fileManager ?? FilesystemManager())
    }

    let statusBarHeight: CGFloat = UIApplication.shared.connectedScenes
            .filter {$0.activationState == .foregroundActive }
            .map {$0 as? UIWindowScene }
            .compactMap { $0 }
            .first?.windows
            .filter({ $0.isKeyWindow }).first?
            .windowScene?.statusBarManager?.statusBarFrame.height ?? 0
    @State var heightOfTitle: CGFloat = 1.0
    @State var scrollOffset: CGFloat = 0.0

    var body: some View {
        List {
            Section {
                Text(viewTitle())
                .font(.largeTitle)
                .textCase(.none)
                .bold()
                .foregroundColor(.primary)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 8, trailing: 16))
                .listRowBackground(Color.clear)
                .textSelection(.enabled)
                .background {
                    GeometryReader { geometry in
                        DispatchQueue.main.async {
                            withAnimation {
                                scrollOffset = geometry.frame(in: .global).minY - statusBarHeight - 51.0
                                heightOfTitle = geometry.frame(in: .local).height
                            }
                        }
                        return Color.clear
                    }
                }
                .opacity(scrollOffset > -heightOfTitle ? 1 : 0)
                HStack(alignment: .center, spacing: 8.0) {
                    Group {
                        ActionButton(text: "Shared.PlayAll", icon: "Play", isPrimary: true) {
                            mediaPlayer.stop()
                            for file in files {
                                if let file = file as? FSFile, file.type == .audio {
                                    mediaPlayer.queueLast(file: file)
                                }
                            }
                            mediaPlayer.play()
                        }
                        ActionButton(text: "Shared.Shuffle", icon: "Shuffle", isPrimary: false) {
                            mediaPlayer.stop()
                            var filesReordered: [FSFile] = []
                            for file in files {
                                if let file = file as? FSFile, file.type == .audio {
                                    filesReordered.append(file)
                                }
                            }
                            filesReordered = filesReordered.shuffled()
                            for file in filesReordered {
                                mediaPlayer.queueLast(file: file)
                            }
                            mediaPlayer.play()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .disabled(!folderContainsPlayableAudio())
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 16, trailing: 16))
                .listRowBackground(Color.clear)
                .alignmentGuide(.listRowSeparatorLeading) { _ in
                    return 0.0
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
            }
            Section {
                ForEach($files, id: \.path) { $file in
                    Group {
                        if let directory = file as? FSDirectory {
                            FBDirectoryRow(directory: directory, storageLocation: storageLocation)
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
                    .listRowBackground(Color.clear)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(
            .linearGradient(
                colors: [.backgroundGradientTop, .backgroundGradientBottom],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                // HACK: Prevent weird animation when going from view to view
                if folderContainsEditableMP3s() {
                    FBMenu(files: $files)
                } else {
                    EmptyView()
                }
            }
            ToolbarItem(placement: .principal) {
                Text(viewTitle())
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .bold()
                    .opacity(scrollOffset <= -heightOfTitle ? 1 : 0)
                    .transition(.opacity.animation(.default.speed(0.2)))
            }
        }
        .overlay {
            if files.count == 0 && currentDirectory == nil {
                TipView(FBNoFilesTip())
                    .padding(20.0)
            } else if files.count == 0 && state.isInitialLoadCompleted {
                ContentUnavailableView("FileBrowser.Hint", systemImage: "questionmark.folder")
                    .font(.body)
            }
        }
        .refreshable {
            refreshFiles()
        }
        .overlay {
            if state.isExtractingZIP {
                // TODO: ProgressAlert should be on a higher level (cover the entire view, instead of just the view inside the navigation stack
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
        .environment(fileManager)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let overrideStorageLocation {
                storageLocation = overrideStorageLocation
            }
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
        .fileBrowserAlerts(state: $state, refreshFiles: refreshFiles)
    }

    func updateFileManagerDirectory() {
        switch storageLocation {
        case .local:
            fileManager.directory = fileManager.documentsDirectoryURL
        case .cloud:
            fileManager.directory = fileManager.cloudDocumentsDirectoryURL
        case .external:
            debugPrint("External directory already set")
        }
    }

    func viewTitle() -> String {
        switch storageLocation {
        case .cloud:
            return currentDirectory?.name ??
            NSLocalizedString("Shared.iCloudDrive", comment: "")
        case .local:
            return currentDirectory?.name ??
            NSLocalizedString("Shared.OnMyDevice", comment: "")
        case .external:
            return currentDirectory?.name ?? fileManager.directory?.lastPathComponent ??
            NSLocalizedString("ViewTitle.Files", comment: "")
        }
    }

    func refreshFiles() {
        updateFileManagerDirectory()
        withAnimation {
            self.files = fileManager.files(in: URL(string: currentDirectory?.path ?? ""))
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
        files.contains { ($0 as? FSFile)?.type == .audio }
    }

    func folderContainsEditableMP3s() -> Bool {
        files.contains { ($0 as? FSFile)?.extension == "mp3" }
    }
}
