//
//  MoreView.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2023/09/11.
//

import SwiftUI

struct MoreView: View {

    @State var moreTabPath: [ViewPath] = []

    var body: some View {
        NavigationStack(path: $moreTabPath) {
            List {
                Section {
                    Link(destination: URL(string: "https://github.com/katagaki/Melodee")!) {
                        HStack {
                            Text(String(localized: "More.GitHub"))
                            Spacer()
                            Text("katagaki/Melodee")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .tint(.primary)
                    NavigationLink("More.Attributions", value: ViewPath.moreAttributions)
                }
            }
            .navigationTitle("ViewTitle.More")
            .navigationDestination(for: ViewPath.self, destination: { viewPath in
                switch viewPath {
                case .moreAttributions:
                    MoreLicensesView()
                default: Color.clear
                }
            })
        }
    }
}
