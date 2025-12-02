/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view that shows video playback.
*/

import SwiftUI

struct AVPlayerView: UIViewControllerRepresentable {
    let viewModel: AVPlayerViewModel

    func makeUIViewController(context: Context) -> some UIViewController {
        return viewModel.makePlayerViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        // Update the `AVPlayerViewController` as needed.
    }
}
