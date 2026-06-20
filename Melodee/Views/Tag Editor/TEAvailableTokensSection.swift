import SwiftUI

struct TEAvailableTokensSection: View {
    var body: some View {
        Section {
            Text("TagEditor.Tokens.Title")
                .font(.title)
                .bold()
                .listRowSeparator(.hidden, edges: .bottom)
                .listRowInsets(.bottom, 0.0)
            TEAvailableTokenRow(
                tokenName: "FILENAME",
                tokenDescription: "TagEditor.Tokens.Filename.Description"
            )
            TEAvailableTokenRow(
                tokenName: "FOLDERNAME",
                tokenDescription: "TagEditor.Tokens.FolderName.Description"
            )
            TEAvailableTokenRow(
                tokenName: "DASHFRONT",
                tokenDescription: "TagEditor.Tokens.DashFront.Description"
            )
            TEAvailableTokenRow(
                tokenName: "DASHBACK",
                tokenDescription: "TagEditor.Tokens.DashBack.Description"
            )
            TEAvailableTokenRow(
                tokenName: "DOTFRONT",
                tokenDescription: "TagEditor.Tokens.DotFront.Description"
            )
            TEAvailableTokenRow(
                tokenName: "DOTBACK",
                tokenDescription: "TagEditor.Tokens.DotBack.Description"
            )
            TEAvailableTokenRow(
                tokenName: "TRACKNUMBER",
                tokenDescription: "TagEditor.Tokens.TrackNumber.Description"
            )
        }
    }
}
