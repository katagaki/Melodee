//
//  TextViewerView.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2023/09/14.
//

import SwiftUI

struct TextViewerView: View {

    @EnvironmentObject var settings: SettingsManager
    @State var file: FSFile
    @State var text: String = ""

    var body: some View {
        TextEditor(text: .constant(text))
            .navigationTitle(file.name)
            .safeAreaInset(edge: .bottom) {
                if settings.showNowPlayingBar {
                    Color.clear
                        .frame(height: 48.0)
                }
            }
            .onAppear {
                do {
                    text = try String(contentsOfFile: file.path)
                } catch {
                    debugPrint(error.localizedDescription)
                }
            }
    }
}
