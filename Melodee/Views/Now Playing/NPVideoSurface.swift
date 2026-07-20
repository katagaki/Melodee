import AVKit
import SwiftUI

// Hosts the shared AVPlayerViewController owned by MediaPlayerManager,
// providing the native playback controls with PiP and fullscreen support.
struct NPVideoSurface: UIViewControllerRepresentable {

    @Environment(MediaPlayerManager.self) var mediaPlayer

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let playerViewController = mediaPlayer.videoPlayerController
        playerViewController.player = mediaPlayer.videoPlayer
        return playerViewController
    }

    func updateUIViewController(_ playerViewController: AVPlayerViewController, context: Context) { }
}
