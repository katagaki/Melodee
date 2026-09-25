import SwiftUI

struct TETagDataSection: View {

    @Binding var tagData: Tag
    var focusedField: FocusState<FocusedField?>.Binding?

    var placeholder: String?

    var body: some View {
        Section {
            if let focusedField = focusedField {
                ListInputRow(title: "Tag.Title", value: $tagData.title,
                             focusedFieldValue: .title, focusedField: focusedField)
                ListInputRow(title: "Tag.Artist", value: $tagData.artist,
                             focusedFieldValue: .artist, focusedField: focusedField)
                ListInputRow(title: "Tag.Album", value: $tagData.album,
                             focusedFieldValue: .album, focusedField: focusedField)
                ListInputRow(title: "Tag.AlbumArtist", value: $tagData.albumArtist,
                             focusedFieldValue: .albumArtist, focusedField: focusedField)
                ListInputRow(title: "Tag.Year", value: $tagData.year,
                             focusedFieldValue: .year, focusedField: focusedField)
                ListInputRow(title: "Tag.TrackNumber", value: $tagData.track,
                             focusedFieldValue: .trackNumber, focusedField: focusedField)
                ListInputRow(title: "Tag.Genre", value: $tagData.genre,
                             focusedFieldValue: .genre, focusedField: focusedField)
                ListInputRow(title: "Tag.Composer", value: $tagData.composer,
                             focusedFieldValue: .composer, focusedField: focusedField)
                ListInputRow(title: "Tag.DiscNumber", value: $tagData.discNumber,
                             focusedFieldValue: .discNumber, focusedField: focusedField)
            } else {
                ListDetailRow(title: "Tag.Title", value: tagData.title)
                ListDetailRow(title: "Tag.Artist", value: tagData.artist)
                ListDetailRow(title: "Tag.Album", value: tagData.album)
                ListDetailRow(title: "Tag.AlbumArtist", value: tagData.albumArtist)
                ListDetailRow(title: "Tag.Year", value: tagData.year)
                ListDetailRow(title: "Tag.TrackNumber", value: tagData.track)
                ListDetailRow(title: "Tag.Genre", value: tagData.genre)
                ListDetailRow(title: "Tag.Composer", value: tagData.composer)
                ListDetailRow(title: "Tag.DiscNumber", value: tagData.discNumber)
            }
        } header: {
            ListSectionHeader(text: "TagEditor.TagData")
                .popoverTip(TETokensTip(), arrowEdge: .bottom)
        }
    }
}
