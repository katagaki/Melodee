import SwiftUI

struct ListFolderRow: View {

    var name: String

    var body: some View {
        HStack(alignment: .center, spacing: 16.0) {
            Image(systemName: "folder.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 28.0, height: 28.0)
                .foregroundStyle(.primary)
            Text(name)
                .font(.body)
                .lineLimit(1)
                .truncationMode(.middle)
        }
    }

}
