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
                    Image(systemName: icon)
                    Text(NSLocalizedString(text, comment: ""))
                        .bold()
                }
            }
            .buttonStyle(.borderedProminent)
            .clipShape(RoundedRectangle(cornerRadius: 99))
        } else {
            Button {
                action()
            } label: {
                HStack(alignment: .center, spacing: 4.0) {
                    Image(systemName: icon)
                    Text(NSLocalizedString(text, comment: ""))
                        .bold()
                }
            }
            .buttonStyle(.bordered)
            .clipShape(RoundedRectangle(cornerRadius: 99))
        }
    }
}
