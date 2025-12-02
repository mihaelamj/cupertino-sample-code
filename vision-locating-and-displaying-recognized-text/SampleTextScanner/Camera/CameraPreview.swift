/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Provides the capture preview.
*/

import AVFoundation
import SwiftUI

struct CameraPreview: UIViewRepresentable {
    @Binding var camera: Camera

    func makeUIView(context: Context) -> some UIView {
        let view = PreviewView()

        view.videoPreviewLayer.session = camera.session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill

        return view
    }

    /// No implementation needed.
    func updateUIView(_ uiView: UIViewType, context: Context) { }
}

class PreviewView: UIView {
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }

    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        return layer as? AVCaptureVideoPreviewLayer ?? AVCaptureVideoPreviewLayer()
    }
}
