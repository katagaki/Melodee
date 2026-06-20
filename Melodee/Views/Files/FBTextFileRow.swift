import SwiftUI

struct FBTextFileRow: View {

    @State var file: FSFile

    var body: some View {
        NavigationLink(value: ViewPath.textViewer(file: file)) {
            ListFileRow(file: .constant(file))
                .tint(.primary)
        }
    }
}
