/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The app's camera view.
*/

import UIKit
import AVFoundation

final class CameraView: UIView {
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }
    var previewLayer: AVCaptureVideoPreviewLayer {
        (layer as? AVCaptureVideoPreviewLayer)!
      }
}
