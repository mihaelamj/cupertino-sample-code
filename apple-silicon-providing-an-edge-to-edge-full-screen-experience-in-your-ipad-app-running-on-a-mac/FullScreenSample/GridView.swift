/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that displays pixel and point grids in the sample's main window.
*/

import UIKit
import CoreGraphics

struct GridViewOptionsKey {
    static let showPixelGrid = "Show pixel grid"
    static let showPointsGrid = "Show points grid"
    static let showBounds = "Show bounds"
    static let showSafeAreaInsets = "Show safe area insets"
    static let showOriginIndicator = "Show origin and postive y-axis indicator"
}

class GridView: UIView {
    
    @Invalidating(.display) var options = [
        GridViewOptionsKey.showPixelGrid: true,
        GridViewOptionsKey.showPointsGrid: true,
        GridViewOptionsKey.showBounds: false,
        GridViewOptionsKey.showSafeAreaInsets: false,
        GridViewOptionsKey.showOriginIndicator: false
    ]

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        guard let window = self.window else { return }
        
        let bounds = self.bounds
        let safeArea = bounds.inset(by: self.safeAreaInsets)
        let pixelsPerPoint = window.screen.nativeScale
        
        context.saveGState()
        
        context.setShouldAntialias(true)
        context.interpolationQuality = .high
        
        // Set the background color to black.
        fillRect(context, rect: bounds, color: .black)
        
        // Draw a grid with white lines. The width of each line is 1 pixel, and
        // there are 10 pixels between each line.
        if options[GridViewOptionsKey.showPixelGrid] ?? true {
            drawGrid(context, bounds: bounds, color: UIColor.white, scale: pixelsPerPoint)
        }
        
        // Draw a grid with red lines. The width of each line is 1 point, and
        // there are 10 points between each line.
        if options[GridViewOptionsKey.showPointsGrid] ?? true {
            drawGrid(context, bounds: bounds, color: UIColor.red, scale: 1.0)
        }
        
        // Draw a blue frame that shows the bounds of the view.
        if options[GridViewOptionsKey.showBounds] ?? true {
            strokeRect(context, rect: bounds, color: .blue, lineWidth: 20.0)
        }
        
        // Draw a green frame that shows the safe area insets of the view.
        if options[GridViewOptionsKey.showSafeAreaInsets] ?? true {
            strokeRect(context, rect: safeArea, color: .green, lineWidth: 5.0)
        }
        
        // Draw a yellow shape that indicates the origin and positive y-axis direction.
        if options[GridViewOptionsKey.showOriginIndicator] ?? true {
            drawOriginIndicator(context, color: .yellow)
        }
        
        context.restoreGState()
    }
    
    func fillRect(_ context: CGContext, rect: CGRect, color: UIColor) {
        context.saveGState()
        
        context.setFillColor(color.cgColor)
        context.fill(rect)
        
        context.restoreGState()
    }
    
    func strokeRect(_ context: CGContext, rect: CGRect, color: UIColor, lineWidth: Double) {
        context.saveGState()
        
        context.setStrokeColor(color.cgColor)
        context.setLineWidth(lineWidth)
        context.stroke(rect)
        
        context.restoreGState()
    }
    
    func drawOriginIndicator(_ context: CGContext, color: UIColor) {
        context.saveGState()
        
        context.setFillColor(color.cgColor)
        context.move(to: CGPoint(x: 0, y: 0))       // The short tip of the indicator points toward the view's origin.
        context.addLine(to: CGPoint(x: 20, y: 10))
        context.addLine(to: CGPoint(x: 10, y: 60))  // The long tip points toward positive y-axis.
        context.closePath()
        context.fillPath()
        
        context.restoreGState()
    }
    
    func drawGrid(_ context: CGContext, bounds: CGRect, color: UIColor, scale: Double) {
        context.saveGState()
        
        let reciprocalScale = 1.0 / scale
        context.scaleBy(x: reciprocalScale, y: reciprocalScale)

        context.setLineWidth(1)
        context.setStrokeColor(color.cgColor)

        let scaleTransform = CGAffineTransform(scaleX: scale, y: scale)
        let scaledBounds = bounds.applying(scaleTransform)
        
        let minX = scaledBounds.minX
        let minY = scaledBounds.minY
        let maxX = scaledBounds.maxX
        let maxY = scaledBounds.maxY
        
        // Draw a line along the x-axis.
        for x in stride(from: minX + 0.5, to: maxX, by: 10.0) {
            drawGridLine(context, moveTo: CGPoint(x: x, y: minY), addLineTo: CGPoint(x: x, y: maxY))
        }

        // Draw a line along the y-axis.
        for y in stride(from: minY + 0.5, to: maxY, by: 10.0) {
            drawGridLine(context, moveTo: CGPoint(x: minX, y: y), addLineTo: CGPoint(x: maxX, y: y))
        }
        
        context.restoreGState()
    }
    
    func drawGridLine(_ context: CGContext, moveTo: CGPoint, addLineTo: CGPoint) {
        context.move(to: moveTo)
        context.addLine(to: addLineTo)
        context.strokePath()
    }
}
