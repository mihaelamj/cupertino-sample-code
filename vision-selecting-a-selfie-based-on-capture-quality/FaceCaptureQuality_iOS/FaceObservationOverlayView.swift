/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Implements the image view responsible for displaying face-capture quality metric results
 coming from live video stream processing frames.
*/

import UIKit
import Vision

class FaceObservationOverlayView: UIView {

    var faceObservation: VNFaceObservation? {
        didSet {
            updateFrame()
        }
    }
    
    init(faceObservation: VNFaceObservation) {
        super.init(frame: .zero)
        self.backgroundColor = .clear
        self.faceObservation = faceObservation
    }
    
    private override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func updateFrame() {
        guard let superView = superview, let faceObservation = faceObservation else {
            frame = .zero
            return
        }
        // Transform from normalized coordinates to coordinates of super view.
        let superFrameWidth = superView.frame.width
        let superFrameHeight = superView.frame.height
        let coordTransform = CGAffineTransform(scaleX: superFrameWidth, y: superFrameHeight)
        // Vision-to-UIKit coordinate transform. Vision is always relative to the lower-left corner.
        let finalTransform = coordTransform.scaledBy(x: 1, y: -1).translatedBy(x: 0, y: -1)
        frame = faceObservation.boundingBox.applying(finalTransform)
        setNeedsDisplay()
    }
    
    override func didMoveToSuperview() {
        updateFrame()
    }
    
    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else {
            return
        }
        // Draw face bounding box.
        ctx.setLineWidth(4)
        ctx.setStrokeColor(UIColor.yellow.cgColor)
        ctx.stroke(bounds)
        if let captureQuality = faceObservation?.faceCaptureQuality {
            // Draw face-capture quality value.
            let attrs = [NSAttributedString.Key.font: UIFont.monospacedDigitSystemFont(ofSize: 20, weight: .medium)]
            let string = NSString(format: "%.2f", captureQuality)
            let size = string.size(withAttributes: attrs)
            let margin = CGFloat(5)
            let rect = CGRect(x: margin, y: bounds.height - size.height - margin,
                              width: size.width + margin * 2, height: size.height + margin * 2)
            let fillColor = UIColor.white.withAlphaComponent(0.5)
            ctx.setFillColor(fillColor.cgColor)
            ctx.fill(rect.insetBy(dx: -margin, dy: -margin))
            ctx.setStrokeColor(UIColor.darkGray.cgColor)
            string.draw(at: rect.origin, withAttributes: attrs)
        }
    }
}
