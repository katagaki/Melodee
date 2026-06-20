import SwiftUI

struct ManageExternalFoldersSheet: View {

    @Environment(\.dismiss) var dismiss
    @Environment(ExternalFoldersManager.self) var externalFolders: ExternalFoldersManager

    @State var isSelectingDirectory: Bool = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(externalFolders.bookmarks) { bookmark in
                        Label(bookmark.name, systemImage: "folder.fill")
                            .listRowBackground(Color.clear)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button {
                                    externalFolders.unlink(bookmark)
                                } label: {
                                    Label("Library.Unlink", systemImage: "link.badge.minus")
                                }
                                .tint(.orange)
                            }
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("ViewTitle.ExternalFolders")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(role: .close) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isSelectingDirectory = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .overlay {
                if externalFolders.bookmarks.isEmpty {
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
                    externalFolders.addBookmark(for: url)
                })
                .ignoresSafeArea(edges: [.bottom])
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}
