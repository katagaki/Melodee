//
//  MoreMoveToCloudView.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2024/03/17.
//

import SwiftUI

struct MoreMoveToCloudView: View {

    @Environment(\.dismiss) var dismiss

    @Binding var storeFilesInCloud: Bool

    var body: some View {
        NavigationStack {
            VStack(alignment: .center, spacing: 16.0) {
                Group {
                    Text(verbatim: "Your Files Are Still On Your Device")
                        .bold()
                        .font(.largeTitle)
                    // swiftlint:disable line_length
                    Text(verbatim: """
iCloud sync has been turned on, but your files are still stored on your device. Before you can use those files, you will need to move those files to iCloud. Melodee can help move all your locally stored files to iCloud automatically.

If you would like to move your files manually, open the Files app, then move your files from On My Device > Melodee to iCloud Drive > Melodee.

You can turn iCloud sync off at any time in the Melodee app from More > iCloud Sync > Files.
""")
                    // swiftlint:enable line_length
                }
                .multilineTextAlignment(.center)
                Spacer()
                Button {
                    // TODO: Move files to iCloud
                } label: {
                    Text(verbatim: "Move Files to iCloud")
                        .bold()
                        .padding([.leading, .trailing], 16.0)
                        .padding([.top, .bottom], 8.0)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .clipShape(.rect(cornerRadius: 16.0))
                Button {
                    dismiss()
                } label: {
                    Text(verbatim: "Move Files Manually")
                        .bold()
                        .padding([.leading, .trailing], 16.0)
                        .padding([.top, .bottom], 8.0)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .clipShape(.rect(cornerRadius: 16.0))
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        storeFilesInCloud = false
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 28.0, height: 28.0)
                            .foregroundStyle(.primary)
                            .symbolRenderingMode(.hierarchical)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
