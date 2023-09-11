//
//  ListSectionHeader.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2023/09/11.
//

import SwiftUI

struct ListSectionHeader: View {
    var text: String

    var body: some View {
        Text(NSLocalizedString(text, comment: ""))
            .fontWeight(.bold)
            .foregroundColor(.primary)
            .textCase(nil)
            .lineLimit(1)
            .truncationMode(.middle)
            .allowsTightening(true)
    }
}
