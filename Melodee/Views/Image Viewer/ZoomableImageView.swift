//
//  ZoomableImageView.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2023/09/15.
//

import Foundation
import SwiftUI
import Zoomy

struct ZoomableImageView: UIViewControllerRepresentable {

    let imagePath: String

    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        let uiImage = UIImage(contentsOfFile: imagePath)
        let imageView = UIImageView(image: uiImage)
        imageView.contentMode = .scaleAspectFit
        if let view = viewController.view {
            view.addSubview(imageView)
            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.pinEdges(to: view)
            viewController.addZoombehavior(for: imageView, settings: .noZoomCancellingSettings)
        }
        return viewController
    }

    func updateUIViewController(_ viewController: UIViewController, context: Context) { }
}
