//
//  TEAvailableTokensSection.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2023/09/12.
//

import Komponents
import SwiftUI

struct TEAvailableTokensSection: View {
    var body: some View {
        Section {
            TEAvailableTokenRow(tokenName: "FILENAME",
                              tokenDescription: "TagEditor.Tokens.Filename.Description")
            TEAvailableTokenRow(tokenName: "FOLDERNAME",
                              tokenDescription: "TagEditor.Tokens.FolderName.Description")
            TEAvailableTokenRow(tokenName: "DASHFRONT",
                              tokenDescription: "TagEditor.Tokens.DashFront.Description")
            TEAvailableTokenRow(tokenName: "DASHBACK",
                              tokenDescription: "TagEditor.Tokens.DashBack.Description")
            TEAvailableTokenRow(tokenName: "DOTFRONT",
                              tokenDescription: "TagEditor.Tokens.DotFront.Description")
            TEAvailableTokenRow(tokenName: "DOTBACK",
                              tokenDescription: "TagEditor.Tokens.DotBack.Description")
            TEAvailableTokenRow(tokenName: "TRACKNUMBER",
                              tokenDescription: "TagEditor.Tokens.TrackNumber.Description")
        } header: {
            VStack(alignment: .leading, spacing: 2.0) {
                ListSectionHeader(text: "TagEditor.Tokens.Title")
            }
        }
    }
}
