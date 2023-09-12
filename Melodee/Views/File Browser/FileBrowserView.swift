//
//  FileBrowserView.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2023/09/11.
//

import SwiftUI
import TipKit
import ZIPFoundation

struct FileBrowserView: View {

    @EnvironmentObject var navigationManager: NavigationManager
    @EnvironmentObject var fileManager: FilesystemManager
    @EnvironmentObject var mediaPlayer: MediaPlayerManager
    @State var currentDirectory: FSDirectory?
    @State var files: [any FilesystemObject] = []

    @State var extractionProgress: Progress?
    @State var isExtractingZIP: Bool = false
    @State var extractionPercentage: Int = 0
    @State var isExtractionCancelling: Bool = false
    @State var isErrorAlertPresenting: Bool = false
    @State var errorText: String = ""

    var body: some View {
        NavigationStack(path: $navigationManager.filesTabPath) {
            List {
                Section {
                    HStack(alignment: .center, spacing: 8.0) {
                        Group {
                            ActionButton(text: "Shared.PlayAll", icon: "Play", isPrimary: true) {
                                mediaPlayer.stop()
                                for file in files {
                                    if let file = file as? FSFile {
                                        mediaPlayer.queueLast(file: file)
                                    }
                                }
                                mediaPlayer.play()
                            }
                            ActionButton(text: "Shared.Shuffle", icon: "Shuffle") {
                                mediaPlayer.stop()
                                var filesReordered: [FSFile] = []
                                for file in files {
                                    if let file = file as? FSFile {
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
                        .disabled(!files.contains(where: { $0 is FSFile }))
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity)
                } header: {
                    Text(currentDirectory?.name ?? NSLocalizedString("ViewTitle.Files", comment: ""))
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(.primary)
                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 16, trailing: 0))
                }
                Section {
                    ForEach($files, id: \.path) { $file in
                        if let directory = file as? FSDirectory {
                            NavigationLink(value: ViewPath.fileBrowser(directory: directory)) {
                                ListFolderRow(name: directory.name)
                            }
                        } else if let file = file as? FSFile {
                            switch file.type {
                            case .audio:
                                Button {
                                    mediaPlayer.playImmediately(file)
                                } label: {
                                    ListFileRow(file: .constant(file))
                                        .tint(.primary)
                                }
                                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                    Button {
                                        withAnimation(.default.speed(2)) {
                                            mediaPlayer.queueNext(file: file)
                                        }
                                    } label: {
                                        Label("Shared.Play.Next",
                                              systemImage: "text.line.first.and.arrowtriangle.forward")
                                    }
                                    .tint(.purple)
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button {
                                        withAnimation(.default.speed(2)) {
                                            mediaPlayer.queueLast(file: file)
                                        }
                                    } label: {
                                        Label("Shared.Play.Last",
                                              systemImage: "text.line.last.and.arrowtriangle.forward")
                                    }
                                    .tint(.orange)
                                }
                                .contextMenu(menuItems: {
                                    FileContextMenu(file: file)
                                })
                            case .image:
                                ListFileRow(file: .constant(file))
                            case .zip:
                                Button {
                                    extractFiles(file: file)
                                } label: {
                                    ListFileRow(file: .constant(file))
                                        .tint(.primary)
                                }
                            }
                        }
                    }
                }
                if folderContainsEditableMP3s() {
                    Section {
                        HStack(alignment: .center, spacing: 8.0) {
                            Group {
                                ActionButton(text: "Shared.EditTag.All", icon: "Tag") {
                                    var validFiles: [FSFile] = []
                                    for file in files {
                                        if let file = file as? FSFile, file.extension == "mp3" {
                                            validFiles.append(file)
                                        }
                                    }
                                    navigationManager.push(ViewPath.tagEditorMultiple(files: validFiles),
                                                           for: .fileManager)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .disabled(!files.contains(where: { $0 is FSFile }))
                        }
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        .buttonStyle(.plain)
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .safeAreaInset(edge: .bottom) {
                Color.clear
                    .frame(height: 72.0)
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
                if files.count == 0 {
                    VStack {
                        ListHintOverlay(image: "questionmark.folder",
                                        text: "FileBrowser.Hint")
                    }
                }
            }
            .overlay {
                if isExtractingZIP {
                    ProgressAlert(title: "Alert.ExtractingZIP.Title",
                                  message: "Alert.ExtractingZIP.Text",
                                  percentage: $extractionPercentage) {
                        withAnimation(.easeOut.speed(2)) {
                            isExtractionCancelling = true
                            extractionProgress?.cancel()
                            extractionPercentage = 0
                            isExtractingZIP = false
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack {
                        if currentDirectory == nil {
                            OpenFilesAppButton()
                                .popoverTip(FileBrowserNoFilesTip(), arrowEdge: .top)
                        }
                    }
                }
            }
            .alert(Text("Alert.ExtractingZIP.Error.Title"), isPresented: $isErrorAlertPresenting, actions: {
                Button("Shared.OK", role: .cancel) { }
            },
                   message: {
                Text(verbatim: errorText)
            })
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            refreshFiles()
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
        }
    }

    func extractFiles(file: FSFile, encoding: String.Encoding = .shiftJIS) {
        withAnimation(.easeOut.speed(2)) {
            isExtractingZIP = true
        }
        let destinationURL = URL(filePath: file.path).deletingPathExtension()
        let destinationDirectory = destinationURL.path().removingPercentEncoding ?? destinationURL.path()
        debugPrint("Attempting to create directory \(destinationDirectory)...")
        fileManager.createDirectory(at: destinationDirectory)
        debugPrint("Attempting to extract ZIP to \(destinationDirectory)...")
        extractionProgress = Progress()
        DispatchQueue.global(qos: .background).async {
            let observation = extractionProgress?.observe(\.fractionCompleted) { progress, _ in
                DispatchQueue.main.async {
                    extractionPercentage = Int(progress.fractionCompleted * 100)
                }
            }
            do {
                try FileManager().unzipItem(at: URL(filePath: file.path),
                                            to: URL(filePath: destinationDirectory),
                                            skipCRC32: true,
                                            progress: extractionProgress,
                                            preferredEncoding: encoding)
                DispatchQueue.main.async {
                    withAnimation(.easeOut.speed(2)) {
                        isExtractingZIP = false
                    }
                    refreshFiles()
                }
            } catch {
                if !isExtractionCancelling {
                    debugPrint("Error occurred while extracting ZIP: \(error.localizedDescription)")
                    if encoding == .shiftJIS {
                        debugPrint("Attempting extraction with UTF-8...")
                        extractFiles(file: file, encoding: .utf8)
                    } else {
                        DispatchQueue.main.async {
                            errorText = error.localizedDescription
                            withAnimation(.easeOut.speed(2)) {
                                isExtractingZIP = false
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                isErrorAlertPresenting = true
                            }
                        }
                    }
                } else {
                    isExtractionCancelling = false
                }
            }
            observation?.invalidate()
        }
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
