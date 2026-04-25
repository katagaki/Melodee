//
//  ListSectionHeader.swift
//  Melodee
//
//  Replacement for Komponents.ListSectionHeader.
//

import SwiftUI

struct ListSectionHeader: View {

    let text: String

    var body: some View {
        Text(LocalizedStringKey(text))
            .bold()
            .foregroundStyle(.primary)
            .textCase(.none)
            .lineLimit(1)
            .truncationMode(.middle)
            .allowsTightening(true)
    }
}
