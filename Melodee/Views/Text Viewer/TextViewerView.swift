//
//  TextViewerView.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2023/09/14.
//

import SwiftUI

struct TextViewerView: View {

    @State var file: FSFile
    @State var text: String = ""

    var body: some View {
        TextEditor(text: .constant(text))
            .navigationTitle(file.name)
            .safeAreaInset(edge: .bottom) {
                Color.clear
                    .frame(height: 56.0)
            }
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
    }
}
