//
//  AvailableTokensSection.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2023/09/12.
//

import SwiftUI

struct AvailableTokensSection: View {
    var body: some View {
        Section {
            AvailableTokenRow(tokenName: "FILENAME",
                              tokenDescription: "TagEditor.Tokens.Filename.Description")
            AvailableTokenRow(tokenName: "FOLDERNAME",
                              tokenDescription: "TagEditor.Tokens.FolderName.Description")
            AvailableTokenRow(tokenName: "DASHFRONT",
                              tokenDescription: "TagEditor.Tokens.DashFront.Description")
            AvailableTokenRow(tokenName: "DASHBACK",
                              tokenDescription: "TagEditor.Tokens.DashBack.Description")
            AvailableTokenRow(tokenName: "DOTFRONT",
                              tokenDescription: "TagEditor.Tokens.DotFront.Description")
            AvailableTokenRow(tokenName: "DOTBACK",
                              tokenDescription: "TagEditor.Tokens.DotBack.Description")
            AvailableTokenRow(tokenName: "TRACKNUMBER",
                              tokenDescription: "TagEditor.Tokens.TrackNumber.Description")
        } header: {
            VStack(alignment: .leading, spacing: 2.0) {
                ListSectionHeader(text: "TagEditor.Tokens.Title")
                    .font(.body)
            }
        }
    }
}
