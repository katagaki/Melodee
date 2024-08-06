//
//  FilesView.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2024/03/16.
//

import Komponents
import SwiftUI

struct FilesView: View {

    @EnvironmentObject var navigationManager: NavigationManager
    @Environment(FilesystemManager.self) var fileManager
    @Environment(PlaylistManager.self) var playlistManager
    @Environment(NowPlayingBarManager.self) var nowPlayingBarManager: NowPlayingBarManager

    @State var isPresentingMoreSheet: Bool = false
    @State var isSelectingExternalDirectory: Bool = false

    @State var isCreatingPlaylist: Bool = false
    @State var newPlaylistName: String = ""

    @State var forceRefreshFlag: Bool = false

    var body: some View {
        @Bindable var playlistManager = playlistManager
        NavigationStack(path: $navigationManager.filesTabPath) {
            List {
                Section {
                    if FileManager.default.ubiquityIdentityToken != nil {
                        NavigationLink(value: ViewPath.fileBrowser(directory: nil, storageLocation: .cloud)) {
                            ListRow(image: "ListIcon.iCloud", title: "Shared.iCloudDrive")
                        }
                    }
                    NavigationLink(value: ViewPath.fileBrowser(directory: nil, storageLocation: .local)) {
                        ListRow(image: "ListIcon.OnMyDevice", title: "Shared.OnMyDevice")
                    }
                    Button {
                        isSelectingExternalDirectory = true
                    } label: {
                        Text("Shared.ExternalFolder")
                    }
                } header: {
                    ListSectionHeader(text: "Shared.StorageLocations")
                }
                Section {
                    Button {
                        let documentsUrl = FileManager.default.urls(for: .documentDirectory,
                                                                    in: .userDomainMask).first!
                        if let sharedUrl = URL(string: "shareddocuments://\(documentsUrl.path)") {
                            if UIApplication.shared.canOpenURL(sharedUrl) {
                                UIApplication.shared.open(sharedUrl, options: [:])
                            }
                        }
                    } label: {
                        ListRow(image: "ListIcon.Files", title: "Shared.OpenFilesApp")
                    }
                }
                Section {
                    
                } header: {
                    ListSectionHeader(text: "Shared.RecentFiles")
                }
                if false {
                    Section {
                        ForEach(playlistManager.playlists, id: \.id) { playlist in
                            NavigationLink(value: ViewPath.playlist(playlist: playlist)) {
                                Label(playlist.name, systemImage: "music.note.list")
                            }
                        }
                    } header: {
                        HStack(alignment: .center, spacing: 8.0) {
                            ListSectionHeader(text: "Shared.Playlists")
                            Spacer()
                            Button {
                                isCreatingPlaylist = true
                            } label: {
                                Image(systemName: "plus")
                            }
                        }
                    }
                }
            }
            .navigationTitle("ViewTitle.Files")
            .refreshable {
                forceRefreshFlag.toggle()
            }
            .navigationDestination(for: ViewPath.self, destination: { viewPath in
                switch viewPath {
                case .fileBrowser(let directory, let storageLocation):
                    FolderView(currentDirectory: directory, overrideStorageLocation: storageLocation)
                case .imageViewer(let file): ImageViewerView(file: file)
                case .textViewer(let file): TextViewerView(file: file)
                case .pdfViewer(let file): PDFViewerView(file: file)
                case .tagEditorSingle(let file): TagEditorView(files: [file])
                case .tagEditorMultiple(let files): TagEditorView(files: files)
                case .playlist(let playlist): PlaylistView(playlist: playlist)
                default: Color.clear
                }
            })
            .sheet(isPresented: $isPresentingMoreSheet) {
                MoreView()
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $isSelectingExternalDirectory) {
                DocumentPicker(allowedUTIs: [.folder], onDocumentPicked: { url in
                    fileManager.directory = url
                    fileManager.storageLocation = .external
                    let isAccessSuccessful = url.startAccessingSecurityScopedResource()
                    if isAccessSuccessful {
                        navigationManager.push(ViewPath.fileBrowser(directory: nil, storageLocation: .external),
                                               for: .fileManager)
                    } else {
                        url.stopAccessingSecurityScopedResource()
                    }
                })
                .ignoresSafeArea(edges: [.bottom])
            }
            .alert("Alert.CreatePlaylist.Title", isPresented: $isCreatingPlaylist, actions: {
                TextField("Shared.NewPlaylistName", text: $newPlaylistName)
                Button("Shared.Create") {
                    isCreatingPlaylist = false
                }
                .disabled(newPlaylistName == "")
                Button("Shared.Cancel", role: .cancel) {
                    newPlaylistName = ""
                }
            })
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isPresentingMoreSheet = true
                    } label: {
                        Label("Shared.More", systemImage: "ellipsis.circle")
                    }
                }
            }
            .onChange(of: isCreatingPlaylist) { oldValue, newValue in
                if oldValue && !newValue {
                    if newPlaylistName != "" {
                        playlistManager.create(newPlaylistName)
                        newPlaylistName = ""
                    }
                }
            }
        }
    }
}
