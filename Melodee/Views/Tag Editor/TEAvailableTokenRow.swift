//
//  TEAvailableTokenRow.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2023/09/12.
//

import SwiftUI

struct TEAvailableTokenRow: View {

    var tokenName: String
    var tokenDescription: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2.0) {
            Text(verbatim: "%\(tokenName)%")
                .textSelection(.enabled)
                .font(.body.monospaced())
                .bold()
            Text(NSLocalizedString(tokenDescription, comment: ""))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
