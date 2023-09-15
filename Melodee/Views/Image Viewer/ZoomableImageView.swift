//
//  ZoomableImageView.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2023/09/15.
//

import Foundation
import SwiftUI
import VisionKit
import Zoomy

struct ZoomableImageView: UIViewControllerRepresentable {

    static let analyzer = ImageAnalyzer()
    static let configuration = ImageAnalyzer.Configuration([.text, .machineReadableCode])

    let imagePath: String

    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        let uiImage = UIImage(contentsOfFile: imagePath)
        let imageView = UIImageView(image: uiImage)
        if let uiImage = uiImage, let view = viewController.view {
            // Configure image view
            imageView.contentMode = .scaleAspectFit
            // Add image view to view controller
            view.addSubview(imageView)
            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.pinEdges(to: view)
            // Configure image view with zoom
            viewController.addZoombehavior(for: imageView, settings: .noZoomCancellingSettings)
            // Configure Live Text for image view
            Task {
                do {
                    let interaction = ImageAnalysisInteraction()
                    let analysis = try await ZoomableImageView.analyzer.analyze(uiImage, 
                                                                                configuration: ZoomableImageView.configuration)
                    imageView.addInteraction(interaction)
                    interaction.analysis = analysis
                    interaction.preferredInteractionTypes = .automatic
                } catch {
                    debugPrint(error.localizedDescription)
                }
            }
        }
        return viewController
    }

    func updateUIViewController(_ viewController: UIViewController, context: Context) { }
}
