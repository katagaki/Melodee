//
//  MoreMenuButton.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2026/06/20.
//

import SwiftUI

struct MoreMenuButton: View {

    @State private var isAttributionsPresented: Bool = false

    var body: some View {
        Menu {
            Link(destination: URL(string: "https://github.com/katagaki/Melodee")!) {
                Label("More.GitHub", systemImage: "chevron.left.forwardslash.chevron.right")
            }
            Button("More.Attributions") {
                isAttributionsPresented = true
            }
        } label: {
            Image(systemName: "ellipsis")
        }
        .sheet(isPresented: $isAttributionsPresented) {
            NavigationStack {
                MoreLicensesView()
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button(role: .close) {
                                isAttributionsPresented = false
                            }
                        }
                    }
            }
        }
    }
}
