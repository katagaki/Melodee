//
//  ImageViewerView.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2023/09/14.
//

import SwiftUI
import VisionKit

struct ImageViewerView: View {

    @State var file: FSFile
    @State var image: UIImage?
    @State var previousZoomLevel = 1.0
    @State var currentZoomLevel = 1.0

    var body: some View {
        GeometryReader { metrics in
            Group {
                if let image = image {
                    ScrollView([.horizontal, .vertical], showsIndicators: false) {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .gesture(
                                MagnifyGesture()
                                    .onChanged { value in
                                        currentZoomLevel = max(1.0, previousZoomLevel + value.magnification - 1)
                                    }
                                    .onEnded { _ in
                                        previousZoomLevel = currentZoomLevel
                                    }
                            )
                            .accessibilityZoomAction { action in
                                if action.direction == .zoomIn {
                                    currentZoomLevel += 1
                                } else {
                                    currentZoomLevel -= 1
                                }
                            }
                            .frame(width: metrics.size.width * currentZoomLevel)
                            .frame(maxHeight: .infinity)
                    }
                } else {
                    ZStack(alignment: .center) {
                        HintOverlay(image: "exclamationmark.triangle", text: "ImageViewer.Erorr.NotSupported")
                            .padding()
                        Color.clear
                    }
                }
            }
            .navigationTitle(file.name)
            .onAppear {
                image = UIImage(contentsOfFile: file.path)
            }
        }
    }
}

// TODO: Implement Live Text
