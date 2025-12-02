/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that provides a preview of the content the camera captures.
*/
import SwiftUI
import AVFoundation

struct CameraPreview: NSViewRepresentable {
    
    private let session: AVCaptureSession
    
    init(session: AVCaptureSession) {
        self.session = session
    }
    
    func makeNSView(context: Context) -> CaptureVideoPreview {
        CaptureVideoPreview(session: session)
    }
    
    func updateNSView(_ nsView: CaptureVideoPreview, context: Context) {
        // The view isn't configurable.
    }
    
    class CaptureVideoPreview: NSView {
        
        init(session: AVCaptureSession) {
            super.init(frame: .zero)
            
            // Creates a preview layer to use as the view's backing layer.
            let previewLayer = AVCaptureVideoPreviewLayer(session: session)
            previewLayer.videoGravity = .resizeAspectFill
            previewLayer.connection?.automaticallyAdjustsVideoMirroring = false
            previewLayer.backgroundColor = .black
            
            // Make this a layer-hosting view. First set the layer, then set `wantsLayer` to true.
            layer = previewLayer
            wantsLayer = true
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}
