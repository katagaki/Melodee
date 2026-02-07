//
//  ProgressAlert.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2023/09/12.
//

import SwiftUI

struct ProgressAlert: View {

    @Environment(\.colorScheme) var colorScheme
    @State var title: String
    @State var message: String
    @Binding var percentage: Int
    @State var onCancel: (() -> Void)?

    var body: some View {
        ZStack(alignment: .center) {
            Color.black.opacity(colorScheme == .dark ? 0.5 : 0.2)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
            VStack(alignment: .center, spacing: 0.0) {
                VStack(alignment: .center, spacing: 10.0) {
                    Text(NSLocalizedString(title, comment: ""))
                        .bold()
                    ProgressView(value: min(Float(percentage), 100.0), total: 100.0)
                        .progressViewStyle(.linear)
                    Text(NSLocalizedString(message, comment: "")
                        .replacingOccurrences(of: "%1", with: String(percentage)))
                    .font(.subheadline)
                }
                .padding()
                if let onCancel = onCancel {
                    Divider()
                    Button {
                        onCancel()
                    } label: {
                        Text("Shared.Cancel")
                            .bold()
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderless)
                    .padding([.top, .bottom], 12.0)
                }
            }
            .background {
                if #available(iOS 26.0, *) {
                    RoundedRectangle(cornerRadius: 24.0)
                        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 24.0))
                } else {
                    RoundedRectangle(cornerRadius: 16.0)
                        .fill(.thickMaterial)
                }
            }
            .padding(.all, 32.0)
        }
        .transition(AnyTransition.opacity)
    }
}
