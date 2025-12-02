/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view that vends the video controller that the video model owns.
*/

import AVKit
import UIKit
import SwiftUI

struct ItemVideoPlayer: UIViewControllerRepresentable {
    let videoModel: VideoModel

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        return videoModel.viewController
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        // No-op
    }
}
