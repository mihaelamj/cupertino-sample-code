/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
WatermarkPage is a PDFPage subclass that implements custom drawing.
*/

import Foundation
import PDFKit

/**
 WatermarkPage subclasses PDFPage so that it can override the draw(with box: to context:) method.
 This method is called by PDFDocument to draw the page into a PDFView. All custom drawing for a PDF
 page should be done through this mechanism.
 
 Custom drawing methods should always be thread-safe and call the super-class method. This is needed
 to draw the original PDFPage content. Custom drawing code can execute before or after this super-class
 call, though order matters! If your graphics run before the super-class call, they are drawn below the
 PDFPage content. Conversely, if your graphics run after the super-class call, they are drawn above the
 PDFPage.
*/
class WatermarkPage: PDFPage {

    // 3. Override PDFPage custom draw
    /// - Tag: OverrideDraw
    override func draw(with box: PDFDisplayBox, to context: CGContext) {

        // Draw original content
        super.draw(with: box, to: context)

        // Draw rotated overlay string
        UIGraphicsPushContext(context)
        context.saveGState()

        let pageBounds = self.bounds(for: box)
        context.translateBy(x: 0.0, y: pageBounds.size.height)
        context.scaleBy(x: 1.0, y: -1.0)
        context.rotate(by: CGFloat.pi / 4.0)

        let string: NSString = "U s e r   3 1 4 1 5 9"
        let attributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key.foregroundColor: #colorLiteral(red: 0.4980392157, green: 0.4980392157, blue: 0.4980392157, alpha: 0.5),
            NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 64)
        ]

        string.draw(at: CGPoint(x: 250, y: 40), withAttributes: attributes)

        context.restoreGState()
        UIGraphicsPopContext()

    }
}
