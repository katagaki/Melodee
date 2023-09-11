//
//  ActionButton.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2023/09/11.
//

import SwiftUI

struct ActionButton: View {
    var text: String
    var icon: String
    var isPrimary: Bool = false
    var action: () -> Void
    var body: some View {
        if isPrimary {
            Button {
                action()
            } label: {
                HStack(alignment: .center, spacing: 4.0) {
                    Image(icon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18.0, height: 18.0)
                    Text(NSLocalizedString(text, comment: ""))
                        .bold()
                }
                .frame(minHeight: 24.0)
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .clipShape(RoundedRectangle(cornerRadius: 99))
        } else {
            Button {
                action()
            } label: {
                HStack(alignment: .center, spacing: 4.0) {
                    Image(icon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18.0, height: 18.0)
                    Text(NSLocalizedString(text, comment: ""))
                        .bold()
                }
                .frame(minHeight: 24.0)
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .clipShape(RoundedRectangle(cornerRadius: 99))
        }
    }
}
