//
//  FolderView.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2023/09/11.
//

import Komponents
import SwiftTagger
import SwiftUI
import TipKit

// swiftlint:disable:next type_body_length
struct FolderView: View {

    @State var fileManager: FilesystemManager
    @Environment(MediaPlayerManager.self) var mediaPlayer

    @State var currentDirectory: FSDirectory?
    @State var files: [any FilesystemObject] = []
    @State var state = FBState()
    @State var isSelectingExternalDirectory = false
    @State var storageLocation: StorageLocation = .local
    @State var isCreatingPlaylist = false

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
                            case .audio: FBAudioFileRow(file: file, sortOption: state.sortOption)
                            case .image: FBImageFileRow(file: file)
                            case .text: FBTextFileRow(file: file)
                            case .pdf: FBPdfFileRow(file: file)
                            case .zip: FBZipFileRow(file: file) { extractZIP(file: file) }
                            case .playlist: FBPlaylistFileRow(file: file)
                            default: ListFileRow(file: .constant(file))
                            }
                        }
                    }
                    .contextMenu {
                        FBContextMenu(state: $state, file: file, extractZIPAction: {
                            if let file = file as? FSFile {
                                extractZIP(file: file)
                            }
                        }, refreshFilesAction: {
                            refreshFiles()
                        })
                    }
                    .listRowBackground(Color.clear)
                }
            }
        }
        .navigationTitle(viewTitle())
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
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    isCreatingPlaylist = true
                } label: {
                    Image(systemName: "plus")
                }
                .disabled(!folderContainsPlayableAudio())
            }
            if #available(iOS 26.0, *) {
                ToolbarSpacer(.fixed, placement: .topBarTrailing)
            }
            ToolbarItemGroup(placement: .topBarTrailing) {
                if folderContainsTaggableFiles() {
                    FBMenu(files: $files)
                }
            }
            if #available(iOS 26.0, *) {
                ToolbarSpacer(.fixed, placement: .topBarTrailing)
            }
            ToolbarItemGroup(placement: .topBarTrailing) {
                FBSortMenu(sortOption: $state.sortOption, sortOrder: $state.sortOrder)
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
            if files.count == 0 && currentDirectory == nil && state.isInitialLoadCompleted {
                // Show ContentUnavailableView with button for root directories
                if storageLocation == .local || storageLocation == .cloud {
                    ContentUnavailableView {
                        Label("FileBrowser.Tip.NoFiles.Title", systemImage: "questionmark.folder.fill")
                    } description: {
                        Text("FileBrowser.Tip.NoFiles.Text")
                    } actions: {
                        Button {
                            openInFilesApp()
                        } label: {
                            Text("FileBrowser.OpenInFiles")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
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
                // TODO: ProgressAlert should be on a higher level
                //       (cover the entire view, instead of just the view inside the navigation stack
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
        .onChange(of: state.sortOption) {
            sortFiles()
        }
        .onChange(of: state.sortOrder) {
            sortFiles()
        }
        .fileBrowserAlerts(state: $state, refreshFiles: refreshFiles)
        .sheet(isPresented: $isCreatingPlaylist) {
            CreatePlaylistSheet(
                audioFiles: files.compactMap { $0 as? FSFile }.filter { $0.type == .audio },
                directoryURL: currentDirectoryURL()
            ) {
                refreshFiles()
            }
        }
    }

    func currentDirectoryURL() -> URL {
        if let currentDirectory {
            return URL(fileURLWithPath: currentDirectory.path)
        }
        switch storageLocation {
        case .local:
            return fileManager.documentsDirectoryURL ?? FileManager.default.temporaryDirectory
        case .cloud:
            return fileManager.cloudDocumentsDirectoryURL ?? FileManager.default.temporaryDirectory
        case .external:
            return fileManager.directory ?? FileManager.default.temporaryDirectory
        }
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
            sortFiles()
            state.isInitialLoadCompleted = true
        }
    }

    func extractZIP(file: FSFile) {
        withAnimation(.easeOut.speed(2)) {
            state.isExtractingZIP = true
        }
        UIApplication.shared.isIdleTimerDisabled = true
        nonisolated(unsafe) let fileManagerRef = fileManager
        fileManager.extractFiles(file: file) {
            MainActor.assumeIsolated {
                state.extractionPercentage =
                    Int((fileManagerRef.extractionProgress?.fractionCompleted ?? 0) * 100)
            }
        } onError: { error in
            MainActor.assumeIsolated {
                UIApplication.shared.isIdleTimerDisabled = false
                withAnimation(.easeOut.speed(2)) {
                    state.isExtractingZIP = false
                    state.errorText = error
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    state.isErrorAlertPresenting = true
                }
            }
        } onCompletion: {
            MainActor.assumeIsolated {
                UIApplication.shared.isIdleTimerDisabled = false
                withAnimation(.easeOut.speed(2)) {
                    state.isExtractingZIP = false
                }
                refreshFiles()
            }
        }
    }

    func folderContainsPlayableAudio() -> Bool {
        files.contains { ($0 as? FSFile)?.type == .audio }
    }

    func folderContainsTaggableFiles() -> Bool {
        files.contains { ($0 as? FSFile)?.isTaggableAudio() ?? false }
    }

    func sortFiles() { // swiftlint:disable:this cyclomatic_complexity function_body_length
        // Separate directories and files
        var directories = files.filter { $0 is FSDirectory }
        var fileItems = files.filter { $0 is FSFile }

        // Sort directories alphabetically (always by name)
        directories.sort { lhs, rhs in
            let result = lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
            return state.sortOrder == .ascending ? result : !result
        }

        // Build tag cache for tag-based sort options
        var tagCache: [String: AudioFile] = [:]
        if state.sortOption != .fileName {
            for item in fileItems {
                if let file = item as? FSFile, file.isTaggableAudio() {
                    do {
                        let audioFile = try AudioFile(location: URL(fileURLWithPath: file.path))
                        tagCache[file.path] = audioFile
                    } catch {
                        debugPrint("Error reading tags for sort: \(error.localizedDescription)")
                    }
                }
            }
        }

        // Sort files, falling back to file name when primary sort values are equal
        fileItems.sort { lhs, rhs in
            guard let lhsFile = lhs as? FSFile, let rhsFile = rhs as? FSFile else {
                return false
            }
            let comparison: ComparisonResult
            switch state.sortOption {
            case .fileName:
                comparison = lhsFile.name.localizedStandardCompare(rhsFile.name)
            case .trackTitle:
                let lhsTitle = tagCache[lhsFile.path]?.title ?? ""
                let rhsTitle = tagCache[rhsFile.path]?.title ?? ""
                comparison = lhsTitle.localizedStandardCompare(rhsTitle)
            case .trackNumber:
                let lhsTrack = tagCache[lhsFile.path]?.trackNumber.index ?? Int.max
                let rhsTrack = tagCache[rhsFile.path]?.trackNumber.index ?? Int.max
                if lhsTrack != rhsTrack {
                    comparison = lhsTrack < rhsTrack ? .orderedAscending : .orderedDescending
                } else {
                    comparison = .orderedSame
                }
            case .albumName:
                let lhsAlbum = tagCache[lhsFile.path]?.album ?? ""
                let rhsAlbum = tagCache[rhsFile.path]?.album ?? ""
                comparison = lhsAlbum.localizedStandardCompare(rhsAlbum)
            case .artistName:
                let lhsArtist = tagCache[lhsFile.path]?.artist ?? ""
                let rhsArtist = tagCache[rhsFile.path]?.artist ?? ""
                comparison = lhsArtist.localizedStandardCompare(rhsArtist)
            }

            // Fall back to file name when primary sort values are equal
            let resolved = comparison == .orderedSame
                ? lhsFile.name.localizedStandardCompare(rhsFile.name)
                : comparison
            return state.sortOrder == .ascending
                ? resolved == .orderedAscending
                : resolved == .orderedDescending
        }

        files = directories + fileItems
    }

    func openInFilesApp() {
        let filesUrl: URL = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first!
        let sharedDocumentsUrlString: String = filesUrl.absoluteString.replacingOccurrences(
            of: "file://",
            with: "shareddocuments://"
        )
        let sharedDocumentsUrl: URL = URL(string: sharedDocumentsUrlString)!
        if UIApplication.shared.canOpenURL(sharedDocumentsUrl) {
            UIApplication.shared.open(sharedDocumentsUrl, options: [:])
        }
    }
}
