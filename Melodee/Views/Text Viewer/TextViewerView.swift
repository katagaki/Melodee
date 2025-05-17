//
//  TextViewerView.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2023/09/14.
//

import SwiftUI

struct TextViewerView: View {

    @Environment(NowPlayingBarManager.self) var nowPlayingBarManager: NowPlayingBarManager

    @State var file: FSFile
    @State var text: String = ""

    var body: some View {
        TextEditor(text: .constant(text))
            .navigationTitle(file.name)
            .onAppear {
                do {
                    if let text = try? String(contentsOfFile: file.path, encoding: .shiftJIS) {
                        self.text = text
                    } else {
                        self.text = try String(contentsOfFile: file.path)
                    }
                } catch {
                    debugPrint(error.localizedDescription)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
                withAnimation(.easeOut) {
                    nowPlayingBarManager.isKeyboardShowing = true
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                withAnimation(.easeOut) {
                    nowPlayingBarManager.isKeyboardShowing = false
                }
            }
    }
}
