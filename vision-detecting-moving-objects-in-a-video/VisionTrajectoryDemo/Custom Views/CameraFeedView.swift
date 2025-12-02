/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that displays the live-camera feed.
*/

import UIKit
import AVFoundation

class CameraFeedView: UIView, NormalizedRectConverting {
    
    // MARK: - Private Properties
    private var previewLayer: AVCaptureVideoPreviewLayer!
    
    // MARK: - Public Properties
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
    
    // MARK: - Life Cycle
    
    init(frame: CGRect, session: AVCaptureSession) {
        super.init(frame: frame)
        previewLayer = layer as? AVCaptureVideoPreviewLayer
        previewLayer.session = session
        previewLayer.videoGravity = .resizeAspect
        previewLayer.connection?.videoOrientation = .landscapeRight
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Public Methods
    
    func viewRectConverted(fromNormalizedContentsRect normalizedRect: CGRect) -> CGRect {
        return previewLayer.layerRectConverted(fromMetadataOutputRect: normalizedRect)
    }
    
}
