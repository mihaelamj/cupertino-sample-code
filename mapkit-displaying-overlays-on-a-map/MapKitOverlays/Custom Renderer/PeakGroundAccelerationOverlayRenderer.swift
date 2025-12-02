/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
This shows an example of how to implement a custom overlay renderer for data that you can't render with MapKit's
 overlay renderering classes.
*/

import Foundation
import CoreLocation
import MapKit

/// `PeakGroundAccelerationOverlayRenderer` is a customized MapKit overlay rendering object that pairs with
/// `PeakGroundAccelerationGrid` to represent the data to render.
class PeakGroundAccelerationOverlayRenderer: MKOverlayRenderer {
    
    private let data: PeakGroundAccelerationGrid
    
    /// A dictionary of the colors to use for a range of peak ground acceleration values.
    private let colorRange: [Range<Double>: CGColor] = [
        0.00..<0.03:            CGColor(red: 0.784, green: 0.784, blue: 0.784, alpha: 1.0),
        0.03..<0.04:            CGColor(red: 0.902, green: 1.000, blue: 1.000, alpha: 1.0),
        0.04..<0.06:            CGColor(red: 0.843, green: 1.000, blue: 1.000, alpha: 1.0),
        0.06..<0.08:            CGColor(red: 0.784, green: 1.000, blue: 1.000, alpha: 1.0),
        0.08..<0.10:            CGColor(red: 0.588, green: 1.000, blue: 0.941, alpha: 1.0),
        0.10..<0.12:            CGColor(red: 0.122, green: 1.000, blue: 0.310, alpha: 1.0),
        0.12..<0.16:            CGColor(red: 0.745, green: 0.941, blue: 0.467, alpha: 1.0),
        0.16..<0.21:            CGColor(red: 1.000, green: 1.000, blue: 0.500, alpha: 1.0),
        0.21..<0.27:            CGColor(red: 1.000, green: 0.784, blue: 0.000, alpha: 1.0),
        0.27..<0.35:            CGColor(red: 1.000, green: 0.392, blue: 0.000, alpha: 1.0),
        0.35..<0.46:            CGColor(red: 1.000, green: 0.392, blue: 0.000, alpha: 1.0),
        0.46..<0.59:            CGColor(red: 1.000, green: 0.000, blue: 0.000, alpha: 1.0),
        0.59..<0.77:            CGColor(red: 0.784, green: 0.471, blue: 0.820, alpha: 1.0),
        0.77..<Double.infinity: CGColor(red: 0.588, green: 0.294, blue: 0.780, alpha: 1.0)
    ]
    
    override init(overlay: MKOverlay) {
        guard let overlay = overlay as? PeakGroundAccelerationGrid else {
            fatalError("Unexpected overlay type passed to \(PeakGroundAccelerationOverlayRenderer.self)")
        }
        data = overlay
        
        super.init(overlay: overlay)
    }
    
    /**
     MapKit calls this method to determine whether this overlay is ready to draw the specific `mapRect`. Because the app fully loads the data for
     the overlay in advance, it always returns `true` if the requested `mapRect` is within the provided data set. If your app is waiting for data so
     it can draw, return `false`, and call `setNeedsDisplay(_:zoomScale:)` when the app can draw the requested rectangle.
     */
    override func canDraw(_ mapRect: MKMapRect, zoomScale: MKZoomScale) -> Bool {
        let result = mapRect.intersects(data.boundingMapRect)
        return result
    }

    /**
     Apps needing to do custom rendering of overlays need to implement `draw(_:zoomScale:in:)`. The system calls this method on multiple background
     queues concurrently to render the overlay as quickly as possible. This sample uses Core Graphics to render the custom overlay, but you can also
     use frameworks like Core Image and Metal by rendering the content that those frameworks draw into the `context` from MapKit.
     */
    /// - Tag: custom_renderer
    override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
        // Don't draw anything that doesn't intersect the data set.
        guard mapRect.intersects(data.boundingMapRect) else { return }
        
        /**
         Determine the section of the overlay to render. MapKit breaks overlays into multiple rectangles for rendering on multiple threads.
         Each call to `draw(_:zoomScale:in:)` should only render within bounds of the provided `mapRect`.
         If your drawing implementation needs to draw content outside of the provided `mapRect` as part of its drawing algorithm, apply a clipping
         rectangle by calling `clip(to:)` on the `CGContext`.
         */
        let intersection = mapRect.intersection(data.boundingMapRect)
        
        // Convert the rectangle this function is drawing into the custom coordinate system for the data.
        let gridRect = GridRect(from: intersection)
        
        /**
         MapKit's provided `mapRect` doesn’t necessarily align to the data's grid coordinates. Adjust the origin of the rectangle outward to land on
         the nearest interval for the grid size, so that when looking up the colors the coordinate grid needs, this drawing correctly draws
         areas that are only partially within the `mapRect`.
         */
        let outsetRect = gridRect.outsetToNearest(data.gridSpacing)
        let drawingGridSpacing = calculateGridSpacingForDrawingAt(mapScale: zoomScale, in: outsetRect)
        
        let matrix = context.ctm
        let inverseMatrix = matrix.inverted()
        
        /**
         Although the `drawingGridSpacing` contains the range of grid coordinates to draw, including cells only partly within the drawing rectangle,
         the partial cells don't draw because `stride(from:to:by:)` doesn't include the end value in the output. To avoid this, this function
         adjusts the `to` value outward by the `drawingGridSpacing` to draw the partial cells.
         */
        let endLatitude = outsetRect.extent.latitude - drawingGridSpacing
        for latitude in stride(from: outsetRect.origin.latitude, to: endLatitude, by: -drawingGridSpacing) {
            let endLongitude = outsetRect.extent.longitude + drawingGridSpacing
            for longitude in stride(from: outsetRect.origin.longitude, to: endLongitude, by: drawingGridSpacing) {

                // Find the diagonal corner points of the rectangle to draw.
                let coord1 = GridCoordinate(latitude: latitude, longitude: longitude)
                let coord2 = GridCoordinate(latitude: coord1.latitude - drawingGridSpacing, longitude: coord1.longitude - drawingGridSpacing)
                
                // Filter out rectangles that have no color to draw.
                guard let acceleration = data.dataPoints[coord1] else { continue }
                let color = colorForAcceleration(acceleration)
                
                // Retrofit the corner points to an unzoomed grid so the renderer still aligns them with the grid when
                // applying the transform matrix in the `CGContext`.
                let point1Conversion = point(for: coord1.mapPoint)
                let point1 = point1Conversion.applying(matrix).rounded().applying(inverseMatrix)
                
                let point2Conversion = point(for: coord2.mapPoint)
                let point2 = point2Conversion.applying(matrix).rounded().applying(inverseMatrix)
                
                // Draw a grid-aligned rectangle between the corner points.
                let drawingRect = CGRect(x: point1.x, y: point1.y, width: point2.x - point1.x, height: point2.y - point1.y)
                context.setAlpha(0.5)
                context.setFillColor(color)
                context.fill(drawingRect)
            }
        }
    }
    
    /**
     Determine the size of the grid for drawing. When possible, render each data point using the data that the grid spacing dictates.
     For small zoom scales where a large part of the world is visible, this grid spacing results in cells smaller than 2 x 2 points onscreen.
     In these situations, use a wider grid spacing (by dropping some cells) to reach the minimum drawing cell size.
     */
    private func calculateGridSpacingForDrawingAt(mapScale: MKZoomScale, in rect: GridRect) -> GridDegrees {
        let minimumDrawingPointSize = 2.0
        var mergedCellScale = 1
        
        let gridSpacing = data.gridSpacing
        let sizingExtent = GridCoordinate(latitude: rect.origin.latitude - gridSpacing, longitude: rect.origin.longitude + gridSpacing)
        let sizingRect = GridRect(origin: rect.origin, extent: sizingExtent)
        
        let screenRect = self.rect(for: sizingRect.mapRect)
        let smallestScreenDimension = abs( min(screenRect.size.width * mapScale, screenRect.size.height * mapScale) )
        
        if smallestScreenDimension < minimumDrawingPointSize {
            mergedCellScale = Int(ceil(1 / smallestScreenDimension))
        }
        
        return gridSpacing * mergedCellScale
    }
    
    /// Find the color to use for a specific acceleration value out of the range of possible values.
    private func colorForAcceleration(_ value: Double) -> CGColor {
        for (range, color) in colorRange {
            if range.contains(value) {
                return color
            }
        }
        
        fatalError("Requesting color for out of bounds acceleration value \(value)")
    }
}

private extension CGPoint {

    /// Rounds the coordinates of a CGPoint to whole numbers.
    func rounded() -> CGPoint {
        return CGPoint(x: round(x), y: round(y))
    }
}
