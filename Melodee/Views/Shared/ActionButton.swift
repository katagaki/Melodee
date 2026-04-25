//
//  ActionButton.swift
//  Melodee
//
//  Replacement for Komponents.ActionButton.
//

import SwiftUI

struct ActionButton: View {

    var text: String
    var icon: String
    var isPrimary: Bool = false
    var action: () -> Void

    var body: some View {
        if isPrimary {
            button
                .buttonStyle(.borderedProminent)
                .clipShape(RoundedRectangle(cornerRadius: 99))
        } else {
            button
                .buttonStyle(.bordered)
                .clipShape(RoundedRectangle(cornerRadius: 99))
        }
    }

    private var button: some View {
        Button {
            action()
        } label: {
            HStack(alignment: .center, spacing: 4.0) {
                Group {
                    if UIImage(named: icon) != nil {
                        Image(icon)
                            .resizable()
                    } else {
                        Image(systemName: icon)
                            .resizable()
                    }
                }
                .scaledToFit()
                .frame(width: 18.0, height: 18.0)
                Text(NSLocalizedString(text, comment: ""))
                    .bold()
            }
            .frame(minHeight: 24.0)
            .frame(maxWidth: .infinity)
        }
    }
}
