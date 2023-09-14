//
//  ImageViewerView.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2023/09/14.
//

import SwiftUI
import VisionKit

struct ImageViewerView: View {

    @EnvironmentObject var settings: SettingsManager
    @State var file: FSFile
    @State var image: UIImage?
    @State var sizeToFit: Bool = false

    var body: some View {
        Group {
            if let image = image {
                Group {
                    if sizeToFit {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                    } else {
                        ScrollView([.vertical, .horizontal], showsIndicators: false) {
                            Image(uiImage: image)
                        }
                        .ignoresSafeArea(edges: [.leading, .trailing])
                    }
                }
                .transition(AnyTransition.opacity.animation(.default))
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
            ToolbarItem(placement: .topBarTrailing) {
                if let image = image {
                    Button {
                        sizeToFit.toggle()
                    } label: {
                        if sizeToFit {
                            Image(systemName: "arrow.up.right.and.arrow.down.left.square.fill")
                        } else {
                            Image(systemName: "arrow.up.right.and.arrow.down.left.square")
                        }
                    }
                } else {
                    Color.clear
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if settings.showNowPlayingBar {
                Color.clear
                    .frame(height: 48.0)
            }
        }
        .onAppear {
            image = UIImage(contentsOfFile: file.path)
        }
    }
}

// TODO: Implement Live Text
