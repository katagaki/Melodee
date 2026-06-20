import SwiftUI

struct LibrarySourcePicker: View {

    @Environment(ExternalFoldersManager.self) var externalFolders: ExternalFoldersManager

    @Binding var selectedSource: LibrarySource
    var isCloudAvailable: Bool

    @State private var isManagingFolders: Bool = false

    var body: some View {
        Menu {
            Button {
                selectedSource = .local
            } label: {
                Label("Shared.OnMyDevice", systemImage: selectedSource == .local ? "checkmark" : "iphone")
            }
            if isCloudAvailable {
                Button {
                    selectedSource = .cloud
                } label: {
                    Label("Shared.iCloudDrive", systemImage: selectedSource == .cloud ? "checkmark" : "cloud")
                }
            }
            if !externalFolders.bookmarks.isEmpty {
                Divider()
                ForEach(externalFolders.bookmarks) { bookmark in
                    Button {
                        selectedSource = .external(bookmark.id)
                    } label: {
                        Label(
                            bookmark.name,
                            systemImage: selectedSource == .external(bookmark.id) ? "checkmark" : "folder"
                        )
                    }
                }
            }
            Divider()
            Button {
                isManagingFolders = true
            } label: {
                Label("Library.ManageFolders", systemImage: "folder.badge.gearshape")
            }
        } label: {
            HStack(alignment: .center, spacing: 4.0) {
                Text(selectedSourceName())
                    .font(.headline)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Image(systemName: "chevron.down.circle.fill")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .symbolRenderingMode(.hierarchical)
                    .layoutPriority(1)
            }
            .padding(.horizontal, 10.0)
            .frame(maxWidth: 190.0)
            .foregroundStyle(.primary)
            .contentShape(.rect)
        }
        .sheet(isPresented: $isManagingFolders) {
            ManageExternalFoldersSheet()
        }
    }

    func selectedSourceName() -> String {
        switch selectedSource {
        case .local:
            return NSLocalizedString("Shared.OnMyDevice", comment: "")
        case .cloud:
            return NSLocalizedString("Shared.iCloudDrive", comment: "")
        case .external(let id):
            return externalFolders.bookmark(with: id)?.name
                ?? NSLocalizedString("Shared.OnMyDevice", comment: "")
        }
    }
}
