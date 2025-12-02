/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A circular progress view, that starts its progress from a 180 degree angle,
 and displays its percentage at the center.
*/

import SwiftUI

struct CircularProgressView: View {
    var value: Double

    var body: some View {
        ProgressView(value: value)
            .progressViewStyle(CircularProgressViewStyle())
            .frame(width: 60, height: 60)
    }
}

private struct CircularProgressViewStyle: ProgressViewStyle {
    func makeBody(configuration: Configuration) -> some View {
        let value = configuration.fractionCompleted ?? 0
        return ArcView(value: value)
    }
}

private struct ArcView: View {
    var value: Double
    
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Circle()
                    .strokeBorder(Color.arcInactiveStroke, style: strokeStyle)
                
                Arc(endAngle: .degrees(360 * value))
                    .strokeBorder(linearGradient, style: strokeStyle)
                    .animation(.easeInOut(duration: 2), value: value)
                
                Text(Int(value * 100), format: .percent)
                    .fontWeight(.thin)
                    .frame(width: proxy.size.width * 0.9)
            }
        }
    }
    
    var strokeStyle: StrokeStyle {
        StrokeStyle(lineWidth: 6, lineCap: .round)
    }
    
    var linearGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [.blue, .purple]),
            startPoint: .bottomLeading,
            endPoint: .topTrailing
        )
    }
}

private struct Arc: InsettableShape {
    var startAngle: Angle = .zero
    var endAngle: Angle
    var insetAmount: Double = .zero

    func path(in rect: CGRect) -> Path {
        let rotation = Angle.degrees(-90)
        var path = Path()
        path.addArc(
            center: CGPoint(x: rect.midX, y: rect.midY),
            radius: rect.width / 2 - insetAmount,
            startAngle: startAngle - rotation,
            endAngle: endAngle - rotation,
            clockwise: false)
        return path
    }

    func inset(by amount: CGFloat) -> some InsettableShape {
        var arc = self
        arc.insetAmount += amount
        return arc
    }
}

struct CircularProgressView_Previews: PreviewProvider {
    static var previews: some View {
        ForEach([0, 0.25, 0.5, 0.75, 1], id: \.self) { value in
            CircularProgressView(value: value)
        }
    }
}
