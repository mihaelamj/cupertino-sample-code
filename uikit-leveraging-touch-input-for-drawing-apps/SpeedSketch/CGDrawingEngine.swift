/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view that is responsible for the drawing. StrokeCGView can draw a StrokeCollection as .calligraphy, .ink or .debug.
*/

import UIKit

enum StrokeViewDisplayOptions: CaseIterable, CustomStringConvertible {
    case calligraphy
    case ink
    case debug

    var description: String {
        switch self {
        case .calligraphy: return "Calligraphy"
        case .ink: return "Ink"
        case .debug: return "Debug"
        }
    }
}

class StrokeCGView: UIView {
    var displayOptions = StrokeViewDisplayOptions.calligraphy {
        didSet {
            if strokeCollection != nil {
                setNeedsDisplay()
            }
            for view in dirtyRectViews {
                view.isHidden = displayOptions != .debug
            }
        }
    }
    
    var strokeCollection: StrokeCollection? {
        didSet {
            if oldValue !== strokeCollection {
                setNeedsDisplay()
            }
            if let lastStroke = strokeCollection?.strokes.last {
                setNeedsDisplay(for: lastStroke)
            }
            strokeToDraw = strokeCollection?.activeStroke
        }
    }
    
    var strokeToDraw: Stroke? {
        didSet {
            if oldValue !== strokeToDraw && oldValue != nil {
                setNeedsDisplay()
            } else {
                if let stroke = strokeToDraw {
                    setNeedsDisplay(for: stroke)
                }
            }
        }
    }

    let strokeColor = UIColor.black

    // Hold samples when attempting to draw lines that are too short.
    private var heldFromSample: StrokeSample?
    private var heldFromSampleUnitVector: CGVector?

    private var lockedAzimuthUnitVector: CGVector?
    private let azimuthLockAltitudeThreshold = CGFloat.pi / 2.0 * 0.80 // locking azimuth at 80% altitude

    // MARK: - Dirty rect calculation and handling.
    var dirtyRectViews: [UIView]!
    var lastEstimatedSample: (Int, StrokeSample)?
    
    func dirtyRects(for stroke: Stroke) -> [CGRect] {
        var result = [CGRect]()
        for range in stroke.updatedRanges() {
            var lowerBound = range.lowerBound
            if lowerBound > 0 { lowerBound -= 1 }
            
            if let (index, _) = lastEstimatedSample {
                if index < lowerBound {
                    lowerBound = index
                }
            }
            
            let samples = stroke.samples
            var upperBound = range.upperBound
            if upperBound < samples.count { upperBound += 1 }
            let dirtyRect = dirtyRectForSampleStride(stroke.samples[lowerBound..<upperBound])
            result.append(dirtyRect)
        }
        if stroke.predictedSamples.isEmpty == false {
            let dirtyRect = dirtyRectForSampleStride(stroke.predictedSamples[0..<stroke.predictedSamples.count])
            result.append(dirtyRect)
        }
        if let previousPredictedSamples = stroke.previousPredictedSamples {
            let dirtyRect = dirtyRectForSampleStride(previousPredictedSamples[0..<previousPredictedSamples.count])
            result.append(dirtyRect)
        }
        return result
    }

    func dirtyRectForSampleStride(_ sampleStride: ArraySlice<StrokeSample>) -> CGRect {
        var first = true
        var frame = CGRect.zero
        for sample in sampleStride {
            let sampleFrame = CGRect(origin: sample.location, size: .zero)
            if first {
                first = false
                frame = sampleFrame
            } else {
                frame = frame.union(sampleFrame)
            }
        }
        let maxStrokeWidth = CGFloat(20.0)
        return frame.insetBy(dx: -1 * maxStrokeWidth, dy: -1 * maxStrokeWidth)
    }

    func updateDirtyRects(for stroke: Stroke) {
        let updateRanges = stroke.updatedRanges()
        for (index, dirtyRectView) in dirtyRectViews.enumerated() {
            if index < updateRanges.count {
                dirtyRectView.alpha = 1.0
                dirtyRectView.frame = dirtyRectForSampleStride(stroke.samples[updateRanges[index]])
            } else {
                dirtyRectView.alpha = 0.0
            }
        }
    }

    func setNeedsDisplay(for stroke: Stroke) {
        for dirtyRect in dirtyRects(for: stroke) {
            setNeedsDisplay(dirtyRect)
        }
    }
    
    // MARK: - Inits
    
    override init(frame: CGRect) {
        super.init(frame: frame)

        layer.drawsAsynchronously = true

        let dirtyRectView = { () -> UIView in
            let view = UIView(frame: CGRect(x: -10, y: -10, width: 0, height: 0))
            view.layer.borderColor = UIColor.red.cgColor
            view.layer.borderWidth = 0.5
            view.isUserInteractionEnabled = false
            view.isHidden = true
            self.addSubview(view)
            return view
        }
        dirtyRectViews = [dirtyRectView(), dirtyRectView()]
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

// MARK: - Drawing methods.

extension StrokeCGView {

    override func draw(_ rect: CGRect) {
        UIColor.white.set()
        UIRectFill(rect)

        // Optimization opportunity: Draw the existing collection in a different view,
        // and only draw each time we add a stroke.
        if let strokeCollection = strokeCollection {
            for stroke in strokeCollection.strokes {
                draw(stroke: stroke, in: rect)
            }
        }

        if let stroke = strokeToDraw {
            draw(stroke: stroke, in: rect)
        }
    }

}

private extension StrokeCGView {

    /**
     Note: this is not a particularily efficient way to draw a great stroke path
     with CoreGraphics. It is just a way to produce an interesting looking result.
     For a real world example you would reuse and cache CGPaths and draw longer
     paths instead of an awful lot of tiny ones, etc. You would also respect the
     draw rect to cull your draw requests. And you would use bezier paths to
     interpolate between the points to get a smooother curve.
     */
    func draw(stroke: Stroke, in rect: CGRect) {

        if displayOptions == .debug {
            updateDirtyRects(for: stroke)
        }

        stroke.clearUpdateInfo()

        guard stroke.samples.isEmpty == false,
            let context = UIGraphicsGetCurrentContext()
            else { return }

        prepareToDraw()
        lineSettings(in: context)

        if stroke.samples.count == 1 {
            // Construct a fake segment to draw for a stroke that is only one point.
            let sample = stroke.samples.first!
            let tempSampleFrom = StrokeSample(
                timestamp: sample.timestamp,
                location: sample.location + CGVector(dx: -0.5, dy: 0.0),
                coalesced: false,
                predicted: false,
                force: sample.force,
                azimuth: sample.azimuth,
                altitude: sample.altitude,
                estimatedProperties: sample.estimatedProperties,
                estimatedPropertiesExpectingUpdates: [])

            let tempSampleTo = StrokeSample(
                timestamp: sample.timestamp,
                location: sample.location + CGVector(dx: 0.5, dy: 0.0),
                coalesced: false,
                predicted: false,
                force: sample.force,
                azimuth: sample.azimuth,
                altitude: sample.altitude,
                estimatedProperties:
                sample.estimatedProperties,
                estimatedPropertiesExpectingUpdates: [])

            let segment = StrokeSegment(sample: tempSampleFrom)
            segment.advanceWithSample(incomingSample: tempSampleTo)
            segment.advanceWithSample(incomingSample: nil)

            draw(segment: segment, in: context)
        } else {
            for segment in stroke {
                draw(segment: segment, in: context)
            }
        }

    }

    func draw(segment: StrokeSegment, in context: CGContext) {

        guard let toSample = segment.toSample else { return }

        let fromSample: StrokeSample = heldFromSample ?? segment.fromSample

        // Skip line segments that are too short.
        if (fromSample.location - toSample.location).quadrance < 0.003 {
            if heldFromSample == nil {
                heldFromSample = fromSample
                heldFromSampleUnitVector = segment.fromSampleUnitNormal
            }
            return
        }

        fillColor(in: context, toSample: toSample, fromSample: fromSample)
        draw(segment: segment, in: context, toSample: toSample, fromSample: fromSample)
        drawDebugMarkings(in: context, fromSample: fromSample)

        if heldFromSample != nil {
            heldFromSample = nil
            heldFromSampleUnitVector = nil
        }
    }

    func draw(segment: StrokeSegment,
              in context: CGContext,
              toSample: StrokeSample,
              fromSample: StrokeSample) {

        let forceAccessBlock = self.forceAccessBlock()

        if displayOptions == .calligraphy {

            drawCalligraphy(in: context, toSample: toSample, fromSample: fromSample, forceAccessBlock: forceAccessBlock)

        } else {

            let unitVector = heldFromSampleUnitVector != nil ? heldFromSampleUnitVector! : segment.fromSampleUnitNormal
            let fromUnitVector = unitVector * forceAccessBlock(fromSample)
            let toUnitVector = segment.toSampleUnitNormal * forceAccessBlock(toSample)

            let isForceEstimated = fromSample.estimatedProperties.contains(.force) || toSample.estimatedProperties.contains(.force)
            if isForceEstimated {
                if lastEstimatedSample == nil {
                    lastEstimatedSample = (segment.fromSampleIndex + 1, toSample)
                }
                forceEstimatedLineSettings(in: context)
            } else {
                lineSettings(in: context)
            }

            context.beginPath()
            context.addLines(between: [
                fromSample.location + fromUnitVector,
                toSample.location + toUnitVector,
                toSample.location - toUnitVector,
                fromSample.location - fromUnitVector
                ])
            context.closePath()
            context.drawPath(using: .fillStroke)

        }

    }

    /// Renders the stroke in a calligraphy-like style.
    /// - Tag: drawCalligraphy
    func drawCalligraphy(in context: CGContext,
                         toSample: StrokeSample,
                         fromSample: StrokeSample,
                         forceAccessBlock: (_ sample: StrokeSample) -> CGFloat) {

        var fromAzimuthUnitVector = Stroke.calligraphyFallbackAzimuthUnitVector
        var toAzimuthUnitVector = Stroke.calligraphyFallbackAzimuthUnitVector

        if fromSample.azimuth != nil {

            if lockedAzimuthUnitVector == nil {
                lockedAzimuthUnitVector = fromSample.azimuthUnitVector
            }
            fromAzimuthUnitVector = fromSample.azimuthUnitVector
            toAzimuthUnitVector = toSample.azimuthUnitVector
            if fromSample.altitude! > azimuthLockAltitudeThreshold {
                fromAzimuthUnitVector = lockedAzimuthUnitVector!
            }
            if toSample.altitude! > azimuthLockAltitudeThreshold {
                toAzimuthUnitVector = lockedAzimuthUnitVector!
            } else {
                lockedAzimuthUnitVector = toAzimuthUnitVector
            }

        }
        // Rotate 90 degrees
        let calligraphyTransform = CGAffineTransform(rotationAngle: CGFloat.pi / 2.0)
        fromAzimuthUnitVector = fromAzimuthUnitVector.applying(calligraphyTransform)
        toAzimuthUnitVector = toAzimuthUnitVector.applying(calligraphyTransform)

        let fromUnitVector = fromAzimuthUnitVector * forceAccessBlock(fromSample)
        let toUnitVector = toAzimuthUnitVector * forceAccessBlock(toSample)

        context.beginPath()
        context.addLines(between: [
            fromSample.location + fromUnitVector,
            toSample.location + toUnitVector,
            toSample.location - toUnitVector,
            fromSample.location - fromUnitVector
            ])
        context.closePath()

        context.drawPath(using: .fillStroke)

    }

    /// Renders altitude and azimuth markings on the stroke.
    /// - Tag: drawDebugMarkings
    func drawDebugMarkings(in context: CGContext, fromSample: StrokeSample) {

        let isEstimated = fromSample.estimatedProperties.contains(.azimuth)
        guard displayOptions == .debug,
            fromSample.predicted == false,
            fromSample.azimuth != nil,
            (!fromSample.coalesced || isEstimated) else {
                return
        }

        let length = CGFloat(20.0)
        let azimuthUnitVector = fromSample.azimuthUnitVector
        let azimuthTarget = fromSample.location + azimuthUnitVector * length
        let altitudeStart = azimuthTarget + (azimuthUnitVector * (length / -2.0))
        let transformToApply = CGAffineTransform(rotationAngle: fromSample.altitude!)
        let altitudeTarget = altitudeStart + (azimuthUnitVector * (length / 2.0)).applying(transformToApply)

        // Draw altitude as black line coming from the center of the azimuth.
        altitudeSettings(in: context)
        context.beginPath()
        context.move(to: altitudeStart)
        context.addLine(to: altitudeTarget)
        context.strokePath()

        // Draw azimuth as blue (or orange if estimated) line.
        azimuthSettings(in: context)
        if isEstimated {
            context.setStrokeColor(UIColor.orange.cgColor)
        }
        context.beginPath()
        context.move(to: fromSample.location)
        context.addLine(to: azimuthTarget)
        context.strokePath()

    }

    func prepareToDraw() {
        lastEstimatedSample = nil
        heldFromSample = nil
        heldFromSampleUnitVector = nil
        lockedAzimuthUnitVector = nil
    }

    func lineSettings(in context: CGContext) {

        if displayOptions == .debug {
            context.setLineWidth(0.5)
            context.setStrokeColor(UIColor.white.cgColor)
        } else {
            context.setLineWidth(0.25)
            context.setStrokeColor(strokeColor.cgColor)
        }

    }

    func forceEstimatedLineSettings(in context: CGContext) {

        if displayOptions == .debug {
            context.setLineWidth(0.5)
            context.setStrokeColor(UIColor.blue.cgColor)
        } else {
            lineSettings(in: context)
        }

    }

    func azimuthSettings(in context: CGContext) {
        context.setLineWidth(1.5)
        context.setStrokeColor(#colorLiteral(red: 0, green: 0.7445889711, blue: 1, alpha: 1).cgColor)
    }

    func altitudeSettings(in context: CGContext) {
        context.setLineWidth(0.5)
        context.setStrokeColor(strokeColor.cgColor)
    }

    func forceAccessBlock() -> (_ sample: StrokeSample) -> CGFloat {

        var forceMultiplier = CGFloat(2.0)
        var forceOffset = CGFloat(0.1)
        var forceAccessBlock = {(sample: StrokeSample) -> CGFloat in
            return sample.forceWithDefault
        }

        if displayOptions == .ink {
            forceAccessBlock = {(sample: StrokeSample) -> CGFloat in
                return sample.perpendicularForce
            }
        }

        // Make the force influence less pronounced for the calligraphy pen.
        if displayOptions == .calligraphy {
            let previousGetter = forceAccessBlock
            forceAccessBlock = {(sample: StrokeSample) -> CGFloat in
                return max(previousGetter(sample), 1.0)
            }
            // make force value less pronounced
            forceMultiplier = 1.0
            forceOffset = 10.0
        }

        let previousGetter = forceAccessBlock
        forceAccessBlock = {(sample: StrokeSample) -> CGFloat in
            return previousGetter(sample) * forceMultiplier + forceOffset
        }

        return forceAccessBlock
    }

    func fillColor(in context: CGContext, toSample: StrokeSample, fromSample: StrokeSample) {
        let fillColorRegular = UIColor.black.cgColor
        let fillColorCoalesced = UIColor.lightGray.cgColor
        let fillColorPredicted = UIColor.red.cgColor

        if toSample.predicted {
            if displayOptions == .debug {
                context.setFillColor(fillColorPredicted)
            }
        } else {
            if displayOptions == .debug && fromSample.coalesced {
                context.setFillColor(fillColorCoalesced)
            } else {
                context.setFillColor(fillColorRegular)
            }
        }
    }

}

