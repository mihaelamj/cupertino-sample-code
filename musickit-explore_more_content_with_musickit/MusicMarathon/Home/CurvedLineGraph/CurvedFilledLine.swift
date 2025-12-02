/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A SwiftUI view to create a filled curve.
*/

import SwiftUI

/// A helper view used in the past workout graph to draw the lines and gradient fill.
struct CurvedFilledLine: View {
    
    // MARK: - Properties
    
    var data: [ActivityData]
    var frame: CGRect
    
    var milesRan: [Double] {
        return data.map { $0.milesRan }
    }
    
    var delta: CGPoint {
        let width = frame.size.width / CGFloat(data.count - 1)
        if let max = milesRan.max() {
            let height = (frame.size.height) / CGFloat(max)
            return CGPoint(x: width, y: height)
        }
        return CGPoint(x: width, y: 0)
    }
    
    // MARK: - View
    
    var body: some View {
        ZStack {
            /// Draw a curved line graph.
            Path.curvedLine(data: milesRan, delta: delta)
                .trim(from: 0, to: 1)
                .stroke(.purple)
                .rotationEffect(.degrees(Self.halfCircleDegrees), anchor: .center)
                .rotation3DEffect(.degrees(Self.halfCircleDegrees), axis: (x: 0, y: 1, z: 0))
            
            /// Fill the curved line.
            Path.curvedFill(data: milesRan, delta: delta)
                .fill(
                    LinearGradient(
                        gradient: Gradient(
                            colors: [
                                .purple.opacity(0.4),
                                .purple.opacity(0.2),
                                .purple.opacity(0)
                            ]
                        ),
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .rotationEffect(.degrees(Self.halfCircleDegrees), anchor: .center)
                .rotation3DEffect(.degrees(Self.halfCircleDegrees), axis: (x: 0, y: 1, z: 0))
                .transition(.opacity)
        }
    }
    
    // MARK: - Constants
    
    private static let halfCircleDegrees: CGFloat = 180
}

// MARK: - Path extension

extension Path {
    fileprivate static func curvedLine(data: [Double], delta: CGPoint) -> Path {
        var path = Path()
        let first = data.first ?? 0
        
        var previous = CGPoint(x: 0, y: CGFloat(first) * delta.y)
        path.move(to: previous)
        for (index, currentEntry) in data.enumerated() {
            let current = CGPoint(x: delta.x * CGFloat(index), y: delta.y * CGFloat(currentEntry))
            let middle = CGPoint(x: (previous.x + current.x) / 2, y: (previous.y + current.y) / 2)
            
            path.addQuadCurve(to: middle, control: Path.control(for: middle, previous))
            path.addQuadCurve(to: current, control: Path.control(for: middle, current))
            previous = current
        }
        return path
    }
    
    fileprivate static func curvedFill(data: [Double], delta: CGPoint) -> Path {
        var path = Path()
        let first = data.first ?? 0
        
        path.move(to: .zero)
        var previous = CGPoint(x: 0, y: CGFloat(first) * delta.y)
        path.addLine(to: previous)
        for (index, currentEntry) in data.enumerated() {
            let current = CGPoint(x: delta.x * CGFloat(index), y: delta.y * CGFloat(currentEntry))
            let middle = CGPoint(x: (previous.x + current.x) / 2, y: (previous.y + current.y) / 2)
            
            path.addQuadCurve(to: middle, control: Path.control(for: middle, previous))
            path.addQuadCurve(to: current, control: Path.control(for: middle, current))
            previous = current
        }
        path.addLine(to: CGPoint(x: previous.x, y: 0))
        path.closeSubpath()
        return path
    }
    
    private static func control(for lhs: CGPoint, _ rhs: CGPoint) -> CGPoint {
        var control = CGPoint(x: (lhs.x + rhs.x) / 2, y: (lhs.y + rhs.y) / 2)
        let diffY = abs(lhs.y - control.y)

        if lhs.y > rhs.y {
            control.y -= diffY
        } else if lhs.y < rhs.y {
            control.y += diffY
        }
        return control
    }
}
