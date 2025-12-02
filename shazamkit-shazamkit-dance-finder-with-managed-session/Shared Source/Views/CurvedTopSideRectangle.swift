/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
View that represents a rectangle with a curved top side.
*/

import SwiftUI

struct CurvedTopSideRectangle: View {
    
    var body: some View {
        
        GeometryReader { reader in
            Path { path in
                let rect = CGRect(origin: .zero, size: reader.size)
                path.move(to: .zero)
                path.addLine(to: CGPoint(x: rect.maxX, y: .zero))
                path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
                path.addQuadCurve(to: CGPoint(x: .zero, y: rect.maxY), control: CGPoint(x: rect.midX, y: rect.maxY + 50))
            }
            .fill(Color.appTertiary)
            .rotationEffect(.degrees(180))
        }
            
    }
}
