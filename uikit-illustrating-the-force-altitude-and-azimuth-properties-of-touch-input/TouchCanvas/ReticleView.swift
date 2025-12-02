/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The `ReticleView` allows visualization of the azimuth and altitude related properties of a `UITouch`
 via an interactive diagram.
*/

import UIKit

class ReticleView: UIView {
    // MARK: Properties

    var actualAzimuthAngle: CGFloat = 0.0 {
        didSet {
            setNeedsLayout()
        }
    }
    var actualAzimuthUnitVector = CGVector(dx: 0, dy: 0) {
        didSet {
            setNeedsLayout()
        }
    }
    var actualAltitudeAngle: CGFloat = 0.0 {
        didSet {
            setNeedsLayout()
        }
    }

    var predictedAzimuthAngle: CGFloat = 0.0 {
        didSet {
            setNeedsLayout()
        }
    }
    var predictedAzimuthUnitVector = CGVector(dx: 0, dy: 0) {
        didSet {
            setNeedsLayout()
        }
    }
    var predictedAltitudeAngle: CGFloat = 0.0 {
        didSet {
            setNeedsLayout()
        }
    }

    private let reticleLayer = CALayer()
    private let radius: CGFloat = 80
    private var reticleImage: UIImage!
    private let reticleColor = UIColor.systemBlue

    private let dotRadius: CGFloat = 8
    private let lineWidth: CGFloat = 2

    var predictedDotLayer = CALayer()
    var predictedLineLayer = CALayer()
    private let predictedIndicatorColor = UIColor.systemRed

    private var dotLayer = CALayer()
    private var lineLayer = CALayer()
    private let indicatorColor = UIColor.systemRed

    // MARK: Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)

        // Set the contentScaleFactor.
        contentScaleFactor = UIScreen.main.scale

        reticleLayer.contentsGravity = CALayerContentsGravity.center
        reticleLayer.position = layer.position
        layer.addSublayer(reticleLayer)

        configureDotLayer(predictedDotLayer, withColor: predictedIndicatorColor)
        predictedDotLayer.isHidden = true
        configureLineLayer(predictedLineLayer, withColor: predictedIndicatorColor)
        predictedLineLayer.isHidden = true

        configureDotLayer(dotLayer, withColor: indicatorColor)
        configureLineLayer(lineLayer, withColor: indicatorColor)

        reticleLayer.addSublayer(predictedDotLayer)
        reticleLayer.addSublayer(predictedLineLayer)
        reticleLayer.addSublayer(dotLayer)
        reticleLayer.addSublayer(lineLayer)

        renderReticleImage()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: UIView Overrides

    override var intrinsicContentSize: CGSize {
        return reticleImage.size
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        CATransaction.setDisableActions(true)

        reticleLayer.position = CGPoint(x: bounds.size.width / 2, y: bounds.size.height / 2)
        layoutIndicator()

        CATransaction.setDisableActions(false)
    }

    // MARK: Convenience

    private func renderReticleImage() {
        let imageRadius = ceil(radius * 1.2)
        let imageSize = CGSize(width: imageRadius * 2, height: imageRadius * 2)
        UIGraphicsBeginImageContextWithOptions(imageSize, false, contentScaleFactor)
        let ctx: CGContext = UIGraphicsGetCurrentContext()!
        ctx.translateBy(x: imageRadius, y: imageRadius)
        ctx.setLineWidth(2.0)
        ctx.setStrokeColor(reticleColor.cgColor)
        ctx.strokeEllipse(in: CGRect(x: -radius, y: -radius, width: radius * 2, height: radius * 2))

        // Draw targeting lines.
        let path = CGMutablePath()
        var transform = CGAffineTransform.identity

        for _ in 0..<4 {
            path.move(to: CGPoint(x: radius * 0.5, y: 0), transform: transform)
            path.addLine(to: CGPoint(x: radius * 1.15, y: 0), transform: transform)
            transform = transform.rotated(by: CGFloat.pi / 2)
        }
        ctx.addPath(path)
        ctx.strokePath()

        reticleImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        reticleLayer.contents = reticleImage.cgImage
        reticleLayer.bounds = CGRect(x: 0, y: 0, width: imageRadius * 2, height: imageRadius * 2)
        reticleLayer.contentsScale = contentScaleFactor
    }

    private func layoutIndicator() {
        // Predicted.
        layoutIndicatorWithAzimuthAngle(predictedAzimuthAngle,
                                        azimuthUnitVector: predictedAzimuthUnitVector,
                                        altitudeAngle: predictedAltitudeAngle,
                                        lineLayer: predictedLineLayer,
                                        dotLayer: predictedDotLayer)

        // Actual.
        layoutIndicatorWithAzimuthAngle(actualAzimuthAngle,
                                        azimuthUnitVector: actualAzimuthUnitVector,
                                        altitudeAngle: actualAltitudeAngle,
                                        lineLayer: lineLayer,
                                        dotLayer: dotLayer)
    }
    
    /// Update the interactive diagram with the new values.
    /// - Tag: DiagramTool
    private func layoutIndicatorWithAzimuthAngle(_ azimuthAngle: CGFloat, azimuthUnitVector: CGVector,
                                                 altitudeAngle: CGFloat, lineLayer: CALayer, dotLayer: CALayer) {
        let reticleBounds = reticleLayer.bounds

        let centeringTransform = CGAffineTransform(translationX: reticleBounds.width / 2, y: reticleBounds.height / 2)

        /*
         Make the length of the indicator's line representative of the `altitudeAngle`. When the angle is
         zero radians (parallel to the screen surface) the line will be at its longest. At `.pi` / 2 radians,
         only the dot on top of the indicator will be visible directly beneath the touch location.
         */
        let altitudeRadius = (1.0 - altitudeAngle / ( CGFloat.pi / 2)) * radius
        var lineTransform = CGAffineTransform(scaleX: altitudeRadius, y: 1)
        
        // Draw the azimuth indicator line as opposite the azimuth by rotating `.pi` radians, for easy visualization.
        var rotationTransform = CGAffineTransform(rotationAngle: azimuthAngle)
        rotationTransform = rotationTransform.rotated(by: CGFloat.pi)
        
        var dotPositionTransform = CGAffineTransform(translationX: -azimuthUnitVector.dx * altitudeRadius, y: -azimuthUnitVector.dy * altitudeRadius)
        dotPositionTransform = dotPositionTransform.concatenating(centeringTransform)
        
        lineTransform = lineTransform.concatenating(rotationTransform)
        lineTransform = lineTransform.concatenating(centeringTransform)
        lineLayer.setAffineTransform(lineTransform)

        dotLayer.setAffineTransform(dotPositionTransform)
    }

    private func configureDotLayer(_ targetLayer: CALayer, withColor color: UIColor) {
        targetLayer.backgroundColor = color.cgColor
        targetLayer.bounds = CGRect(x: 0, y: 0, width: dotRadius * 2, height: dotRadius * 2)
        targetLayer.cornerRadius = dotRadius
        targetLayer.position = CGPoint.zero
    }

    private func configureLineLayer(_ targetLayer: CALayer, withColor color: UIColor) {
        targetLayer.backgroundColor = color.cgColor
        targetLayer.bounds = CGRect(x: 0, y: 0, width: 1, height: lineWidth)
        targetLayer.anchorPoint = CGPoint(x: 0, y: 0.5)
        targetLayer.position = CGPoint.zero
    }
}
