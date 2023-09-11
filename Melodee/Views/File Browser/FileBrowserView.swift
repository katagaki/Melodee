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
                        .font(.title)
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
                                    Label("Shared.Play.Next", systemImage: "text.line.first.and.arrowtriangle.forward")
                                }
                                .tint(.purple)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button {
                                    withAnimation(.default.speed(2)) {
                                        mediaPlayer.queueLast(file: file)
                                    }
                                } label: {
                                    Label("Shared.Play.Last", systemImage: "text.line.last.and.arrowtriangle.forward")
                                }
                                .tint(.orange)
                            }
                        }
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
                default: Color.clear
                }
            })
            .refreshable {
                refreshFiles()
            }
            .background {
                if files.count == 0 {
                    VStack {
                        ListHintOverlay(image: "questionmark.folder",
                                        text: "FileBrowser.Hint")
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack {
                        if currentDirectory == nil {
                            Button {
                                let documentsUrl = FileManager.default.urls(for: .documentDirectory,
                                                                            in: .userDomainMask).first!
                                if let sharedUrl = URL(string: "shareddocuments://\(documentsUrl.path)") {
                                    if UIApplication.shared.canOpenURL(sharedUrl) {
                                        UIApplication.shared.open(sharedUrl, options: [:])
                                    }
                                }
                            } label: {
                                HStack(alignment: .center, spacing: 8.0) {
                                    Image("SystemApps.Files")
                                        .resizable()
                                        .frame(width: 30.0, height: 30.0)
                                        .clipShape(RoundedRectangle(cornerRadius: 6.0))
                                        .overlay {
                                            RoundedRectangle(cornerRadius: 6.0)
                                                .stroke(.black, lineWidth: 1/3)
                                                .opacity(0.3)
                                        }
                                    Text("Shared.OpenFilesApp")
                                }
                            }
                            .popoverTip(FileBrowserNoFilesTip(), arrowEdge: .top)
                        }
                    }
                }
            }
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

}
