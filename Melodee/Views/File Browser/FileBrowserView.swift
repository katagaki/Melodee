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
    @State var currentDirectory: FSDirectory?
    @State var files: [any FilesystemObject] = []

    var body: some View {
        NavigationStack(path: $navigationManager.filesTabPath) {
            List($files, id: \.path) { $file in
                if let directory = file as? FSDirectory {
                    NavigationLink(value: ViewPath.fileBrowser(directory: directory)) {
                        ListFolderRow(name: directory.name)
                    }
                } else if let file = file as? FSFile {
                    ListFileRow(file: .constant(file))
                        .listRowInsets(EdgeInsets(top: 8.0, leading: 0.0, bottom: 8.0, trailing: 0.0))
                }
            }
            .listStyle(.plain)
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
            .navigationTitle(currentDirectory != nil ?
                             currentDirectory!.name :
                                NSLocalizedString("ViewTitle.Files", comment: ""))
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
