//
//  PlaylistDetailView.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2024/03/16.
//

import Komponents
import SwiftUI
import UniformTypeIdentifiers

struct PlaylistDetailView: View {

    @Environment(MediaPlayerManager.self) var mediaPlayer
    @Environment(\.modelContext) private var modelContext

    var playlist: Playlist

    @State var resolvedFiles: [ResolvedPlaylistFile] = []
    @State var isAddingFiles: Bool = false
    @State var isRenamingPlaylist: Bool = false
    @State var editedPlaylistName: String = ""
    @State var isExporting: Bool = false
    @State var exportURL: URL?

    let statusBarHeight: CGFloat = UIApplication.shared.connectedScenes
        .filter { $0.activationState == .foregroundActive }
        .map { $0 as? UIWindowScene }
        .compactMap { $0 }
        .first?.windows
        .filter({ $0.isKeyWindow }).first?
        .windowScene?.statusBarManager?.statusBarFrame.height ?? 0
    @State var heightOfTitle: CGFloat = 1.0
    @State var scrollOffset: CGFloat = 0.0

    var audioFiles: [ResolvedPlaylistFile] {
        resolvedFiles.filter { $0.file.type == .audio }
    }

    var nonAudioFiles: [ResolvedPlaylistFile] {
        resolvedFiles.filter { $0.file.type != .audio }
    }

    var body: some View {
        List {
            Section {
                Text(playlist.name)
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
                            playAll()
                        }
                        ActionButton(text: "Shared.Shuffle", icon: "Shuffle", isPrimary: false) {
                            shuffleAll()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .disabled(audioFiles.isEmpty)
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 16, trailing: 16))
                .listRowBackground(Color.clear)
                .alignmentGuide(.listRowSeparatorLeading) { _ in
                    return 0.0
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
            }
            if !audioFiles.isEmpty {
                Section {
                    ForEach(audioFiles) { item in
                        FBAudioFileRow(file: item.file)
                            .listRowBackground(Color.clear)
                    }
                    .onDelete { offsets in
                        deleteItems(from: audioFiles, at: offsets)
                    }
                }
            }
            if !nonAudioFiles.isEmpty {
                Section("Playlists.OtherFiles") {
                    ForEach(nonAudioFiles) { item in
                        playlistFileRow(for: item.file)
                            .listRowBackground(Color.clear)
                    }
                    .onDelete { offsets in
                        deleteItems(from: nonAudioFiles, at: offsets)
                    }
                }
            }
            if resolvedFiles.isEmpty {
                Section {
                    ContentUnavailableView {
                        Label("Playlists.Detail.Empty.Title", systemImage: "music.note")
                    } description: {
                        Text("Playlists.Detail.Empty.Description")
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
        .navigationTitle(playlist.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    isAddingFiles = true
                } label: {
                    Image(systemName: "plus")
                }
            }
            if #available(iOS 26.0, *) {
                ToolbarSpacer(.fixed, placement: .topBarTrailing)
            }
            ToolbarItemGroup(placement: .topBarTrailing) {
                Menu {
                    Button {
                        editedPlaylistName = playlist.name
                        isRenamingPlaylist = true
                    } label: {
                        Label("Playlists.Rename", systemImage: "pencil")
                    }
                    Menu {
                        Button {
                            exportAsJSON()
                        } label: {
                            Label("Playlists.Export.JSON", systemImage: "doc.text")
                        }
                        Button {
                            exportAsM3U8()
                        } label: {
                            Label("Playlists.Export.M3U8", systemImage: "music.note.list")
                        }
                    } label: {
                        Label("Playlists.Export", systemImage: "square.and.arrow.up")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
            ToolbarItem(placement: .principal) {
                Text(playlist.name)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .bold()
                    .opacity(scrollOffset <= -heightOfTitle ? 1 : 0)
                    .transition(.opacity.animation(.default.speed(0.2)))
            }
        }
        .sheet(isPresented: $isAddingFiles) {
            DocumentPicker(
                allowedUTIs: [.audio, .image, .text, .pdf, .zip],
                onDocumentPicked: { url in
                    addFileToPlaylist(url: url)
                }
            )
            .ignoresSafeArea(edges: [.bottom])
        }
        .alert("Playlists.Rename", isPresented: $isRenamingPlaylist) {
            TextField("Playlists.PlaylistName", text: $editedPlaylistName)
            Button("Shared.Cancel", role: .cancel) { }
            Button("Shared.Save") {
                let trimmed = editedPlaylistName.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    playlist.name = trimmed
                }
            }
        }
        .onAppear {
            resolveFiles()
        }
        .sheet(isPresented: $isExporting) {
            if let exportURL {
                ShareSheet(activityItems: [exportURL])
                    .onDisappear {
                        try? FileManager.default.removeItem(at: exportURL)
                        self.exportURL = nil
                    }
            }
        }
    }

    func resolveFiles() {
        var resolved: [ResolvedPlaylistFile] = []
        for bookmark in playlist.sortedBookmarks {
            if let file = bookmark.resolveFile() {
                resolved.append(ResolvedPlaylistFile(bookmark: bookmark, file: file))
            }
        }
        resolvedFiles = resolved
    }

    func addFileToPlaylist(url: URL) {
        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing { url.stopAccessingSecurityScopedResource() }
        }
        do {
            try playlist.addFile(url: url)
            resolveFiles()
        } catch {
            debugPrint("Failed to add file to playlist: \(error.localizedDescription)")
        }
    }

    func deleteItems(from section: [ResolvedPlaylistFile], at offsets: IndexSet) {
        for index in offsets {
            let item = section[index]
            if let bookmarkIndex = playlist.fileBookmarks.firstIndex(where: {
                $0.persistentModelID == item.bookmark.persistentModelID
            }) {
                let bookmark = playlist.fileBookmarks[bookmarkIndex]
                playlist.fileBookmarks.remove(at: bookmarkIndex)
                modelContext.delete(bookmark)
            }
        }
        resolveFiles()
    }

    func playAll() {
        mediaPlayer.stop()
        for item in audioFiles {
            mediaPlayer.queueLast(file: item.file)
        }
        mediaPlayer.play()
    }

    func shuffleAll() {
        mediaPlayer.stop()
        let shuffled = audioFiles.shuffled()
        for item in shuffled {
            mediaPlayer.queueLast(file: item.file)
        }
        mediaPlayer.play()
    }

    @ViewBuilder
    func playlistFileRow(for file: FSFile) -> some View {
        switch file.type {
        case .image: FBImageFileRow(file: file)
        case .text: FBTextFileRow(file: file)
        case .pdf: FBPdfFileRow(file: file)
        case .zip: ListFileRow(file: .constant(file))
        default: ListFileRow(file: .constant(file))
        }
    }

    func exportAsJSON() {
        let json = playlist.toJSON()
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(json) else { return }
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(playlist.name).json")
        try? data.write(to: tempURL)
        exportURL = tempURL
        isExporting = true
    }

    func exportAsM3U8() {
        let content = playlist.toM3U8()
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(playlist.name).m3u8")
        try? content.write(to: tempURL, atomically: true, encoding: .utf8)
        exportURL = tempURL
        isExporting = true
    }
}

struct ResolvedPlaylistFile: Identifiable {
    let bookmark: PlaylistFileBookmark
    let file: FSFile
    var id: String { bookmark.order.description + file.path }
}
