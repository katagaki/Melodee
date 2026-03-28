//
//  FilesView.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2024/03/16.
//

import SwiftUI

struct ExternalFolderBookmark: Identifiable, Codable {
    var id: UUID
    var name: String
    var bookmarkData: Data

    init(name: String, bookmarkData: Data) {
        self.id = UUID()
        self.name = name
        self.bookmarkData = bookmarkData
    }
}

struct FilesView: View {

    @State var isSelectingDirectory: Bool = false
    @State var bookmarks: [ExternalFolderBookmark] = []

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(bookmarks) { bookmark in
                        if let url = resolveBookmark(bookmark) {
                            NavigationLink(value: ViewPath.fileBrowser(
                                directory: FSDirectory(
                                    name: bookmark.name,
                                    path: url.path(percentEncoded: false),
                                    files: []
                                ),
                                storageLocation: .external
                            )) {
                                Label(bookmark.name, systemImage: "folder.fill")
                            }
                            .listRowBackground(Color.clear)
                        }
                    }
                    .onDelete(perform: deleteBookmarks)
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
            .navigationTitle("ViewTitle.ExternalFolders")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        isSelectingDirectory = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .overlay {
                if bookmarks.isEmpty {
                    ContentUnavailableView {
                        Label("Library.NoFolder.Title", systemImage: "folder.badge.questionmark")
                    } description: {
                        Text("Library.NoFolder.Description")
                    } actions: {
                        Button {
                            isSelectingDirectory = true
                        } label: {
                            Text("Library.AddFolder")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            .sheet(isPresented: $isSelectingDirectory) {
                DocumentPicker(allowedUTIs: [.folder], onDocumentPicked: { url in
                    addBookmark(for: url)
                })
                .ignoresSafeArea(edges: [.bottom])
            }
            .onAppear {
                loadBookmarks()
            }
            .hasFileBrowserNavigationDestinations()
        }
    }

    // MARK: - Bookmark persistence

    func loadBookmarks() {
        guard let data = UserDefaults.standard.data(forKey: "ExternalFolderBookmarks"),
              let decoded = try? JSONDecoder().decode([ExternalFolderBookmark].self, from: data) else {
            // Migrate from old single bookmark if present
            migrateOldBookmark()
            return
        }
        bookmarks = decoded

        // Start accessing all bookmarked resources
        for bookmark in bookmarks {
            _ = resolveBookmark(bookmark)
        }
    }

    func saveBookmarks() {
        guard let data = try? JSONEncoder().encode(bookmarks) else { return }
        UserDefaults.standard.set(data, forKey: "ExternalFolderBookmarks")
    }

    func addBookmark(for url: URL) {
        let accessing = url.startAccessingSecurityScopedResource()
        guard accessing else { return }

        do {
            let bookmarkData = try url.bookmarkData(
                options: .minimalBookmark,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            // Don't add duplicates
            if !bookmarks.contains(where: { $0.name == url.lastPathComponent }) {
                let bookmark = ExternalFolderBookmark(
                    name: url.lastPathComponent,
                    bookmarkData: bookmarkData
                )
                bookmarks.append(bookmark)
                saveBookmarks()
            }
        } catch {
            debugPrint("Failed to create bookmark: \(error)")
            url.stopAccessingSecurityScopedResource()
        }
    }

    func deleteBookmarks(at offsets: IndexSet) {
        bookmarks.remove(atOffsets: offsets)
        saveBookmarks()
    }

    func resolveBookmark(_ bookmark: ExternalFolderBookmark) -> URL? {
        do {
            var isStale = false
            let url = try URL(
                resolvingBookmarkData: bookmark.bookmarkData,
                options: .withoutUI,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
            if isStale {
                // Refresh bookmark data
                if let newData = try? url.bookmarkData(
                    options: .minimalBookmark,
                    includingResourceValuesForKeys: nil,
                    relativeTo: nil
                ), let index = bookmarks.firstIndex(where: { $0.id == bookmark.id }) {
                    bookmarks[index] = ExternalFolderBookmark(
                        name: bookmark.name,
                        bookmarkData: newData
                    )
                    saveBookmarks()
                }
            }
            _ = url.startAccessingSecurityScopedResource()
            return url
        } catch {
            debugPrint("Failed to resolve bookmark: \(error)")
            return nil
        }
    }

    // MARK: - Migration

    func migrateOldBookmark() {
        guard let oldData = UserDefaults.standard.data(forKey: "ExternalFolderBookmark") else {
            return
        }
        do {
            var isStale = false
            let url = try URL(
                resolvingBookmarkData: oldData,
                options: .withoutUI,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
            let bookmarkData = isStale
                ? try url.bookmarkData(options: .minimalBookmark, includingResourceValuesForKeys: nil, relativeTo: nil)
                : oldData
            let bookmark = ExternalFolderBookmark(name: url.lastPathComponent, bookmarkData: bookmarkData)
            bookmarks = [bookmark]
            saveBookmarks()
            UserDefaults.standard.removeObject(forKey: "ExternalFolderBookmark")
            _ = url.startAccessingSecurityScopedResource()
        } catch {
            debugPrint("Failed to migrate old bookmark: \(error)")
            UserDefaults.standard.removeObject(forKey: "ExternalFolderBookmark")
        }
    }
}
