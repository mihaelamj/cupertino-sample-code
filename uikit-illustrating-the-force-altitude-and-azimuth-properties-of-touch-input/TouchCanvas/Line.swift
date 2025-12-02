/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Contains the `Line` and `LinePoint` types used to represent and draw lines derived from touches.
*/

import UIKit

class Line: NSObject {
    // MARK: Properties

    // The live line.
    private var points = [LinePoint]()

    // Use the estimation index of the touch to track points awaiting updates.
    private var pointsWaitingForUpdatesByEstimationIndex = [NSNumber: LinePoint]()

    // Points already drawn into 'frozen' representation of this line.
    private var committedPoints = [LinePoint]()

    var isComplete: Bool {
        return pointsWaitingForUpdatesByEstimationIndex.isEmpty
    }

    func updateWithTouch(_ touch: UITouch) -> (Bool, CGRect) {
        if let estimationUpdateIndex = touch.estimationUpdateIndex,
            let point = pointsWaitingForUpdatesByEstimationIndex[estimationUpdateIndex] {
            var rect = updateRectForExistingPoint(point)
            let didUpdate = point.updateWithTouch(touch)
            if didUpdate {
                rect = rect.union(updateRectForExistingPoint(point))
            }
            if point.estimatedPropertiesExpectingUpdates == [] {
                pointsWaitingForUpdatesByEstimationIndex.removeValue(forKey: estimationUpdateIndex)
            }
            return (didUpdate, rect)
        }
        return (false, CGRect.null)
    }

    // MARK: Interface

    func addPointOfType(_ pointType: LinePoint.PointType, for touch: UITouch, in view: UIView) -> CGRect {
        let previousPoint = points.last
        let previousSequenceNumber = previousPoint?.sequenceNumber ?? -1
        let point = LinePoint(touch: touch, sequenceNumber: previousSequenceNumber + 1, pointType: pointType, locatedIn: view)

        if let estimationIndex = point.estimationUpdateIndex {
            if !point.estimatedPropertiesExpectingUpdates.isEmpty {
                pointsWaitingForUpdatesByEstimationIndex[estimationIndex] = point
            }
        }

        points.append(point)

        let updateRect = updateRectForLinePoint(point, previousPoint: previousPoint)

        return updateRect
    }

    func removePointsWithType(_ type: LinePoint.PointType) -> CGRect {
        var updateRect = CGRect.null
        var priorPoint: LinePoint?

        points = points.filter { point in
            let keepPoint = !point.pointType.contains(type)

            if !keepPoint {
                var rect = self.updateRectForLinePoint(point)

                if let priorPoint = priorPoint {
                    rect = rect.union(updateRectForLinePoint(priorPoint))
                }

                updateRect = updateRect.union(rect)
            }

            priorPoint = point

            return keepPoint
        }

        return updateRect
    }

    func cancel() -> CGRect {
        // Process each point in the line and accumulate the `CGRect` containing all the points.
        let updateRect = points.reduce(CGRect.null) { accumulated, point in
            // Update the type set to include `.Cancelled`.
            point.pointType.formUnion(.cancelled)

            /*
                Union the `CGRect` for this point with accumulated `CGRect` and return it. The result is
                supplied to the next invocation of the closure.
            */
            return accumulated.union(updateRectForLinePoint(point))
        }

        return updateRect
    }

    // MARK: Drawing

    /// Draw line points to the canvas, altering the drawing based on the data originally collected from `UITouch`.
    /// - Tag: DrawLine
    func drawInContext(_ context: CGContext, isDebuggingEnabled: Bool, usePreciseLocation: Bool) {
        var maybePriorPoint: LinePoint?

        for point in points {
            guard let priorPoint = maybePriorPoint else {
                maybePriorPoint = point
                continue
            }

            let color = strokeColor(for: point, useDebugColors: isDebuggingEnabled)
            
            let location = usePreciseLocation ? point.preciseLocation : point.location
            let priorLocation = usePreciseLocation ? priorPoint.preciseLocation : priorPoint.location

            context.setStrokeColor(color.cgColor)

            context.beginPath()

            context.move(to: CGPoint(x: priorLocation.x, y: priorLocation.y))
            context.addLine(to: CGPoint(x: location.x, y: location.y))

            context.setLineWidth(point.magnitude)
            
            context.strokePath()

            // Draw azimuith and elevation on all non-coalesced points when debugging.
            let pointType = point.pointType
            if isDebuggingEnabled && !pointType.contains(.coalesced) && !pointType.contains(.predicted) && !pointType.contains(.finger) {
                context.beginPath()
                context.setStrokeColor(UIColor.systemRed.cgColor)
                context.setLineWidth(0.5)
                context.move(to: CGPoint(x: location.x, y: location.y))
                var targetPoint = CGPoint(x: 0.5 + 10.0 * cos(point.altitudeAngle), y: 0.0)
                targetPoint = targetPoint.applying(CGAffineTransform(rotationAngle: point.azimuthAngle))
                targetPoint.x += location.x
                targetPoint.y += location.y
                context.addLine(to: CGPoint(x: targetPoint.x, y: targetPoint.y))
                context.strokePath()
            }

            maybePriorPoint = point
        }
    }

    func drawFixedPointsInContext(_ context: CGContext, isDebuggingEnabled: Bool, usePreciseLocation: Bool, commitAll: Bool = false) {
        let allPoints = points
        var committing = [LinePoint]()

        if commitAll {
            committing = allPoints
            points.removeAll()
        } else {
            for (index, point) in allPoints.enumerated() {
                // Only points whose type does not include `.needsUpdate` or `.predicted` and are not last or prior to last point can be committed.
                guard point.pointType.intersection([.needsUpdate, .predicted]).isEmpty && index < allPoints.count - 2 else {
                    committing.append(points.first!)
                    break
                }

                guard index > 0 else { continue }

                // First time to this point should be index 1 if there is a line segment that can be committed.
                let removed = points.removeFirst()
                committing.append(removed)
            }
        }
        // If only one point could be committed, no further action is required. Otherwise, draw the `committedLine`.
        guard committing.count > 1 else { return }

        let committedLine = Line()
        committedLine.points = committing
        committedLine.drawInContext(context, isDebuggingEnabled: isDebuggingEnabled, usePreciseLocation: usePreciseLocation)

        if !committedPoints.isEmpty {
            // Remove what was the last point committed point; it is also the first point being committed now.
            committedPoints.removeLast()
        }

        // Store the points being committed for redrawing later in a different style if needed.
        committedPoints.append(contentsOf: committing)
    }

    func drawCommitedPoints(in context: CGContext, isDebuggingEnabled: Bool, usePreciseLocation: Bool) {
        let committedLine = Line()
        committedLine.points = committedPoints
        committedLine.drawInContext(context, isDebuggingEnabled: isDebuggingEnabled, usePreciseLocation: usePreciseLocation)
    }

    // MARK: Convenience

    private func updateRectForLinePoint(_ point: LinePoint) -> CGRect {
        var rect = CGRect(origin: point.location, size: CGSize.zero)

        // The negative magnitude ensures an outset rectangle.
        let magnitude = -3 * point.magnitude - 2
        rect = rect.insetBy(dx: magnitude, dy: magnitude)

        return rect
    }

    private func updateRectForLinePoint(_ point: LinePoint, previousPoint optionalPreviousPoint: LinePoint? = nil) -> CGRect {
        var rect = CGRect(origin: point.location, size: CGSize.zero)

        var pointMagnitude = point.magnitude

        if let previousPoint = optionalPreviousPoint {
            pointMagnitude = max(pointMagnitude, previousPoint.magnitude)
            rect = rect.union( CGRect(origin: previousPoint.location, size: CGSize.zero))
        }

        // The negative magnitude ensures an outset rectangle.
        let magnitude = -3.0 * pointMagnitude - 2.0
        rect = rect.insetBy(dx: magnitude, dy: magnitude)

        return rect
    }

    private func updateRectForExistingPoint(_ point: LinePoint) -> CGRect {
        var rect = updateRectForLinePoint(point)

        let arrayIndex = point.sequenceNumber - points.first!.sequenceNumber

        if arrayIndex > 0 {
            rect = rect.union(updateRectForLinePoint(point, previousPoint: points[arrayIndex - 1]))
        }
        if arrayIndex + 1 < points.count {
            rect = rect.union(updateRectForLinePoint(point, previousPoint: points[arrayIndex + 1]))
        }
        return rect
    }
    
    private func strokeColor(for point: LinePoint, useDebugColors: Bool) -> UIColor {
        // This color will used by default for `.standard` touches.
        guard let defaultSrokeColor = UIColor(named: "defaultStrokeColor") else { fatalError("Color missing from asset catalog") }
        var color = defaultSrokeColor
        
        let pointType = point.pointType
        if useDebugColors {
            
            if pointType.contains(.cancelled) {
                // Cancelled touches happen when the touch was interrupted. To see an example, draw in the
                // app while activiting the app switcher at the same time.
                color = UIColor.systemRed
            } else if pointType.contains(.needsUpdate) {
                // One way to see the needs update color is to look at the line just behind the tip of Apple Pencil.
                // After the update is applied, this flag is removed, and the color of the line segment changes.
                color = UIColor.systemOrange
            } else if pointType.contains(.coalesced) {
                // With finger input, you are more likely to see the coalesced touch color on devices that
                // report touches at 60 Hz frequency. Some devices report touches at a higher frequency, so
                // touch coalescing is less frequent.
                color = UIColor.systemGreen
            } else if pointType.contains(.predicted) {
                // Predicted touches are drawn in this sample for demonstration, but are typically used to influence the
                // drawing indirectly, such as with a smoothing algorithm. Points derived from predicted touches
                // should be removed from the line at the next event, so this color appears only briefly.
                color = UIColor.systemBlue
            } else if pointType.contains(.finger) {
                color = UIColor.systemPurple
            }
        } else {
            if pointType.contains(.cancelled) {
                color = UIColor.clear
            } else if pointType.contains(.finger) {
                color = UIColor.systemPurple
            }
            if pointType.contains(.predicted) && !pointType.contains(.cancelled) {
                color = color.withAlphaComponent(0.5)
            }
        }
        
        return color
    }
}

class LinePoint: NSObject {
    // MARK: Types

    struct PointType: OptionSet {
        // MARK: Properties

        let rawValue: Int

        // MARK: Options

        static let standard = PointType([])
        
        static let coalesced = PointType(rawValue: 1 << 0)
        static let predicted = PointType(rawValue: 1 << 1)
        static let needsUpdate = PointType(rawValue: 1 << 2)
        static let updated = PointType(rawValue: 1 << 3)
        static let cancelled = PointType(rawValue: 1 << 4)
        static let finger = PointType(rawValue: 1 << 5)
    }

    // MARK: Properties

    var sequenceNumber: Int
    let timestamp: TimeInterval
    var force: CGFloat
    var location: CGPoint
    var preciseLocation: CGPoint
    var estimatedPropertiesExpectingUpdates: UITouch.Properties
    var estimatedProperties: UITouch.Properties
    let type: UITouch.TouchType
    var altitudeAngle: CGFloat
    var azimuthAngle: CGFloat
    let estimationUpdateIndex: NSNumber?

    var pointType: PointType
    
    /// Clamp the force of a touch to a usable range.
    /// - Tag: Magnitude
    var magnitude: CGFloat {
        return max(force, 0.025)
    }

    // MARK: Initialization

    init(touch: UITouch, sequenceNumber: Int, pointType: PointType, locatedIn view: UIView) {
        self.sequenceNumber = sequenceNumber
        self.type = touch.type
        self.pointType = pointType

        timestamp = touch.timestamp
        location = touch.location(in: view)
        preciseLocation = touch.preciseLocation(in: view)
        azimuthAngle = touch.azimuthAngle(in: view)
        estimatedProperties = touch.estimatedProperties
        estimatedPropertiesExpectingUpdates = touch.estimatedPropertiesExpectingUpdates
        altitudeAngle = touch.altitudeAngle
        force = (type == .pencil || touch.force > 0) ? touch.force : 1.0

        if !estimatedPropertiesExpectingUpdates.isEmpty {
            self.pointType.formUnion(.needsUpdate)
        }

        estimationUpdateIndex = touch.estimationUpdateIndex
    }

    /// Gather the properties on a `UITouch` for force, altitude, azimuth, and location.
    /// - Tag: TouchProperties
    func updateWithTouch(_ touch: UITouch) -> Bool {
        guard let estimationUpdateIndex = touch.estimationUpdateIndex, estimationUpdateIndex == estimationUpdateIndex else { return false }

        // An array of the touch properties that may be of interest.
        let touchProperties: [UITouch.Properties] = [.altitude, .azimuth, .force, .location]

        // Iterate through possible properties.
        touchProperties.forEach { (touchProperty) in
            // If an update to this property is not expected, exit scope for this property and continue to the next property.
            guard estimatedPropertiesExpectingUpdates.contains(touchProperty) else { return }
            
            // Update the value of the point with the value from the touch's property.
            switch touchProperty {
                case .force:
                    force = touch.force
                case .azimuth:
                    azimuthAngle = touch.azimuthAngle(in: touch.view)
                case .altitude:
                    altitudeAngle = touch.altitudeAngle
                case .location:
                    location = touch.location(in: touch.view)
                    preciseLocation = touch.preciseLocation(in: touch.view)
                default:
                    ()
            }
            
            if !touch.estimatedProperties.contains(touchProperty) {
                // Flag that this point now has a 'final' value for this property.
                estimatedProperties.subtract(touchProperty)
            }

            if !touch.estimatedPropertiesExpectingUpdates.contains(touchProperty) {
                // Flag that this point is no longer expecting updates for this property.
                estimatedPropertiesExpectingUpdates.subtract(touchProperty)
                
                if estimatedPropertiesExpectingUpdates.isEmpty {
                    // Flag that this point has been updated and no longer needs updates.
                    pointType.subtract(.needsUpdate)
                    pointType.formUnion(.updated)
                }
            }
        }

        return true
    }
}
