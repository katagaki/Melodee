//
//  PDFViewerView.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2023/09/14.
//

import PDFKit
import SwiftUI

struct PDFViewerView: View {

    @State var file: FSFile

    var body: some View {
        PDFKitView(file: file)
            .navigationTitle(file.name)
    }
}

struct PDFKitView: UIViewRepresentable {

    var file: FSFile

    func makeUIView(context: UIViewRepresentableContext<PDFKitView>) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = PDFDocument(url: URL(filePath: file.path))
        pdfView.autoScales = true
        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: UIViewRepresentableContext<PDFKitView>) { }
}
