//
//  OpenFilesAppButton.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2023/09/12.
//

import SwiftUI

struct OpenFilesAppButton: View {
    var body: some View {
        Button {
            let documentsUrl = FileManager.default.urls(for: .documentDirectory,
                                                        in: .userDomainMask).first!
            if let sharedUrl = URL(string: "shareddocuments://\(documentsUrl.path)") {
                if UIApplication.shared.canOpenURL(sharedUrl) {
                    UIApplication.shared.open(sharedUrl, options: [:])
                }
            }
        } label: {
            HStack(alignment: .center, spacing: 8.0) {
                Image("SystemApps.Files")
                    .resizable()
                    .frame(width: 30.0, height: 30.0)
                    .clipShape(RoundedRectangle(cornerRadius: 6.0))
                    .overlay {
                        RoundedRectangle(cornerRadius: 6.0)
                            .stroke(.black, lineWidth: 1/3)
                            .opacity(0.3)
                    }
                Text("Shared.OpenFilesApp")
            }
        }
    }
}
