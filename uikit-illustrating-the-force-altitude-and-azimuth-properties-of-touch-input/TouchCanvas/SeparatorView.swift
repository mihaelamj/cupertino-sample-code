/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The `SeparatorView` shows where the drawing canvas ends.
*/

import UIKit

class SeparatorView: UIView {

    override func draw(_ rect: CGRect) {
        if let context = UIGraphicsGetCurrentContext() {
            context.setLineWidth(1)
            context.move(to: .zero)
            context.addLine(to: CGPoint(x: rect.size.width, y: 0))
            
            if #available(iOS 13.0, *) {
                context.setStrokeColor(UIColor.opaqueSeparator.cgColor)
            } else {
                context.setStrokeColor(UIColor.lightGray.cgColor)
            }
            context.strokePath()
        }
    }
}
