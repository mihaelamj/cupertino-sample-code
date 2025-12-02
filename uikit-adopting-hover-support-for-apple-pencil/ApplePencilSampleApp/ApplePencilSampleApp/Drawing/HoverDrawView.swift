/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The hover drawing view that acts as the canvas for drawing Apple Pencil strokes.
*/

import UIKit
import CoreGraphics

class HoverDrawView: UIView {
    
    /// Constants for rendering the hover preview.
    let maxPreviewZOffset = 1.0
    let fadeZOffset = 0.8
    
    /// Constants for drawing strokes.
    private let strokeWidth: CGFloat = 4.0
    private let lineWidth: CGFloat = 0.5
    private let strokeColor = UIColor.systemBlue
    private let pathTailSize = 3
    
    /// The bitmap context all strokes render into.
    private var bitmapContext: CGContext?
    private var bitmapContextSize = CGSize(width: 0, height: 0)
    private var bezierPath = UIBezierPath()
    
    /// The CAShapeLayer for live drawing of a new stroke and for hover preview.
    private var shapeLayer: CAShapeLayer?
    
    /// Gesture recognizers for drawing and hovering.
    private var drawGestureRecognizer: DrawGestureRecognizer?
    private var hoverGestureRecognizer: UIHoverGestureRecognizer?

    /// State tracking that updates during drawing and hovering.
    private var isPreviewing = false
    private var previewAlpha = 1.0
    private var isDrawing = false
    private var strokePathTail: [CGPoint] = []

    // MARK: - View Layout
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateBitmapContext()
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        guard superview != nil else {
            bitmapContext = nil
            layer.contents = nil
            shapeLayer?.removeFromSuperlayer()
            shapeLayer = nil
            return
        }

        configureGestureRecognizers()
        updateShapeLayer()
    }
    
    // MARK: - Gesture Recognizers
    /// - Tag: ConfigureGestureRecognizers
    private func configureGestureRecognizers() {
        if drawGestureRecognizer == nil {
            let drawGesture = DrawGestureRecognizer(target: self, action: #selector(drawGesture(_:)))
            drawGesture.minimumPressDuration = 0
            drawGesture.allowableMovement = .greatestFiniteMagnitude
            addGestureRecognizer(drawGesture)
            drawGestureRecognizer = drawGesture
        }
        
        if hoverGestureRecognizer == nil {
            let hoverGesture = UIHoverGestureRecognizer(target: self, action: #selector(hoverGesture(_:)))
            // Enable the line below to restrict hover to just Apple Pencil (not trackpad).
            // hoverGesture.allowedTouchTypes = [ UITouch.TouchType.pencil.rawValue as NSNumber ]
            addGestureRecognizer(hoverGesture)
            hoverGestureRecognizer = hoverGesture
        }
    }
    
    /// Implements the draw gesture recognizer for drawing strokes.
    /// - Tag: DrawGesture
    @objc
    private func drawGesture(_ gesture: UIGestureRecognizer) {
        let point = gesture.location(in: self)
        switch gesture.state {
        case .began:
            resetPath()
            isPreviewing = false
            isDrawing = true
            updatePath(point: point)
        case .changed:
            if let drawGR = drawGestureRecognizer,
               let currentTouch = drawGR.currentTouch,
               let currentEvent = drawGR.currentEvent,
               let touches = currentEvent.coalescedTouches(for: currentTouch) {
                for touch in touches {
                    let point = touch.preciseLocation(in: self)
                    updatePath(point: point)
                }
            } else {
                updatePath(point: point)
            }
        case .ended:
            updateContextWithCurrentPath()
            resetPath()
            isDrawing = false

        default:
            // Gesture failed or cancelled.
            resetPath()
            isDrawing = false
        }
    }
    
    /// Implements the hover gesture recognizer for the visual hover preview.
    /// - Tag: HoverGesture
    @objc
    private func hoverGesture(_ gesture: UIHoverGestureRecognizer) {
        
        // Wait for the draw gesture to end before starting hover preview rendering.
        guard !isDrawing else { return }
        
        let point = gesture.location(in: self)
        switch gesture.state {
        case .began:
            resetPath()
            isPreviewing = true
            updatePath(point: point)
            
        case .changed:
            var zOffset = 0.0
            if #available(iOS 16.1, *) {
                zOffset = gesture.zOffset
            }
            if zOffset > maxPreviewZOffset {
                resetPath()
                isPreviewing = false
            } else {
                // Calculate the opacity for the hover preview effect according
                // to the distance between the pointing device and iPad screen.
                previewAlpha = 1.0 - max(zOffset - fadeZOffset, 0.0) / (maxPreviewZOffset - fadeZOffset)
                isPreviewing = true
                updatePath(point: point)
            }
            
        default:
            resetPath()
            isPreviewing = false
        }
    }
    
    // MARK: - Drawing
    
    private func updateShapeLayer() {
        
        if shapeLayer == nil {
            let newLayer = CAShapeLayer()
            newLayer.fillColor = strokeColor.cgColor
            newLayer.strokeColor = strokeColor.cgColor
            newLayer.lineWidth = lineWidth
            layer.addSublayer(newLayer)
            shapeLayer = newLayer
        }
        
        let opacity = isPreviewing ? previewAlpha : 1.0
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        shapeLayer?.frame = bounds
        shapeLayer?.path = currentCGPath()
        shapeLayer?.opacity = Float(opacity)
        CATransaction.commit()
    }
    
    private func updateBitmapContext() {
        let scale = window?.screen.nativeScale ?? 1.0
        
        // Clear the image from the layer when the size changes.
        let size = CGSize(width: round(bounds.size.width * scale), height: round(bounds.size.height * scale))
        if size != bitmapContextSize {
            layer.contents = nil
            
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let width = Int(size.width)
            let bpr = width * 4
            let alphaInfo: CGImageAlphaInfo = .premultipliedFirst
            if let context = CGContext(data: nil,
                                       width: width,
                                       height: Int(size.height),
                                       bitsPerComponent: 8,
                                       bytesPerRow: bpr,
                                       space: colorSpace,
                                       bitmapInfo: alphaInfo.rawValue) {
                context.setLineWidth(lineWidth)
                context.setStrokeColor(strokeColor.cgColor)
                context.setFillColor(strokeColor.cgColor)

                context.translateBy(x: 0, y: size.height)
                context.scaleBy(x: scale, y: -scale)
                
                bitmapContext = context
            }
        }
    }
    
    private func currentCGPath() -> CGPath {
        
        var path = bezierPath
        
        // For hover preview, use the tail path that's constantly updating instead.
        if isPreviewing {
            path = UIBezierPath()
            
            for point in strokePathTail {
                if path.isEmpty {
                    path.move(to: point)
                } else {
                    path.addLine(to: point)
                }
            }
        }
        
        // To be able to use this path in a CAShapeLayer, always stroke the path.
        return path.cgPath.copy(strokingWithWidth: strokeWidth, lineCap: .round, lineJoin: .round, miterLimit: strokeWidth)
    }
    
    private func updateLayerImage() {
        if let image = bitmapContext?.makeImage() {
            CATransaction.begin()
            CATransaction.setDisableActions(false)
            layer.contents = image
            CATransaction.commit()
        }
    }
    
    private func updateContextWithCurrentPath() {
        guard let context = bitmapContext, !bezierPath.isEmpty else { return }
        
        let currentPath = currentCGPath()
        context.saveGState()
        context.addPath(currentPath)
        context.strokePath()
        context.addPath(currentPath)
        context.fillPath()
        context.restoreGState()
        
        // Update the layer contents as well.
        updateLayerImage()
    }
    
    private func updatePath(point: CGPoint) {
        while strokePathTail.count >= pathTailSize {
            strokePathTail.remove(at: 0)
        }
        strokePathTail.append(point)
        
        if bezierPath.isEmpty {
            bezierPath.move(to: point)
        } else {
            bezierPath.addLine(to: point)
        }
        updateShapeLayer()
    }
    
    private func resetPath() {
        bezierPath.removeAllPoints()
        strokePathTail = []
        updateShapeLayer()
    }
}
