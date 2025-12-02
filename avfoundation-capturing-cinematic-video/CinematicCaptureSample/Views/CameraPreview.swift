/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that presents a video preview of the captured content.
*/

import SwiftUI
@preconcurrency import AVFoundation

struct CameraPreview: UIViewRepresentable {

    private let preview: CALayer

    init(preview: CALayer) {
        self.preview = preview
    }

    func makeUIView(context: Context) -> PreviewView {
        PreviewView(preview: preview)
    }

    func updateUIView(_ previewView: PreviewView, context: Context) {
        // No implementation needed.
    }

    class PreviewView: UIView {

        let preview: CALayer

        init(preview: CALayer) {
            self.preview = preview
            super.init(frame: .zero)
            layer.addSublayer(preview)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func layoutSubviews() {
            preview.frame = bounds
        }
    }
}
