/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that displays a live camera feed.
*/

import SwiftUI
import AVKit

/// A SwiftUI wrapper around an  AV capture video preview layer.
struct CameraPreview: UIViewRepresentable {

    public let layer: AVCaptureVideoPreviewLayer

    func makeUIView(context: Context) -> PreviewLayerView {
        return PreviewLayerView(layer: layer)
    }

    func updateUIView(_ uiView: PreviewLayerView, context: Context) { }

    // MARK: -

    /// A `UIView` that renders an `AVCaptureVideoPreviewLayer`.
    class PreviewLayerView: UIView {

        var previewLayer: AVCaptureVideoPreviewLayer

        public init(layer: AVCaptureVideoPreviewLayer) {
            self.previewLayer = layer
            layer.videoGravity = .resizeAspectFill
            super.init(frame: layer.bounds)
            self.layer.addSublayer(layer)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func layoutSubviews() {
            previewLayer.frame = self.frame
            super.layoutSubviews()
        }
    }
}
