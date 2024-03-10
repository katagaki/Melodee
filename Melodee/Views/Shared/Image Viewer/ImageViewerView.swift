//
//  ImageViewerView.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2023/09/14.
//

import SwiftUI
import VariableBlurView

struct ImageViewerView: View {

    @Environment(\.colorScheme) var colorScheme
    @State var file: FSFile
    @State var image: UIImage?
    let gradient = LinearGradient(
            gradient: Gradient(stops: [
                .init(color: .black, location: 0.8),
                .init(color: .clear, location: 1.0)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )

    var body: some View {
        GeometryReader { metrics in
            Group {
                if image != nil {
                    ZoomableImageView(imagePath: file.path)
                } else {
                    ZStack(alignment: .center) {
                        HintOverlay(image: "exclamationmark.triangle", text: "ImageViewer.Erorr.NotSupported")
                            .padding()
                        Color.clear
                    }
                }
            }
            .navigationTitle(file.name)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(file.name)
                        .truncationMode(.middle)
                        .bold()
                        .padding([.leading, .trailing], 8.0)
                        .padding([.top, .bottom], 4.0)
                        .background(Material.thin)
                        .clipShape(RoundedRectangle(cornerRadius: 99))
                }
            }
            .overlay {
                ZStack(alignment: .top) {
                    Group {
                        if colorScheme == .dark {
                            VariableBlurView()
                                .mask(gradient)
                                .allowsHitTesting(false)
                        } else {
                            VariableBlurView()
                                .mask(gradient)
                                .allowsHitTesting(false)
                        }
                    }
                    .frame(height: metrics.safeAreaInsets.top + 16.0)
                    .ignoresSafeArea(edges: .top)
                    Color.clear
                }
            }
            .safeAreaInset(edge: .bottom) {
                Color.clear
                    .frame(height: 48.0)
            }
            .onAppear {
                image = UIImage(contentsOfFile: file.path)
            }
        }
    }
}
