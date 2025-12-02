/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that presents a video preview of the captured content.
*/

import SwiftUI

struct CameraFrameView: UIViewRepresentable {
    
    /*
     In this sample, `preview` is an instance of `AVSampleBufferDisplayLayer`.
     `CameraFeed` uses the layer's `sampleBufferRenderer` to enqueue the `PixelBuffer`
     that `CameraFrameProvider` provides for rendering.
     */
    private let preview: CALayer

    init(preview: CALayer) {
        self.preview = preview
    }
    
    func makeUIView(context: Context) -> SampleBufferPreview {
        SampleBufferPreview(preview: preview)
    }
    
    func updateUIView(_ previewView: SampleBufferPreview, context: Context) {
        // Updates the state of the specified view with new information from SwiftUI.
    }

    final class SampleBufferPreview: UIView {

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
