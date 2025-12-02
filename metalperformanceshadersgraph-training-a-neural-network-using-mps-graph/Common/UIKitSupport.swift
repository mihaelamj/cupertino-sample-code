/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Class containing methods for UIKit resources
*/

import UIKit

extension UILabel {
    
    func updateText(text: String) {
        DispatchQueue.main.async {
            self.text = text
        }
    }
    
}

extension UIToolbar {
    
    func toggleInteraction(isEnabled: Bool) {
        DispatchQueue.main.async {
            self.isUserInteractionEnabled = isEnabled
            self.alpha = isEnabled ? 1 : 0.5
        }
    }

}

protocol CanvasDelegate: AnyObject {
    func canvasUpdated()
}

class Canvas: UIView {
    
    weak var delegate: CanvasDelegate?
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        guard let context = UIGraphicsGetCurrentContext() else { return }
                
        context.setLineWidth(25)
        context.setLineCap(.round)
        context.setStrokeColor(UIColor.white.cgColor)
        
        lines.forEach({ line in
            for (ind, point) in line.enumerated() {
                if ind == 0 {
                    context.move(to: point)
                } else {
                    context.addLine(to: point)
                }
            }
        })
        
        context.strokePath()
    }
    
    var lines = [[CGPoint]]()
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        lines.append([CGPoint]())
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard  let point = touches.first?.location(in: self) else {
            return
        }
        
        guard var line = lines.popLast() else { return }
        
        line.append(point)
        lines.append(line)
        
        setNeedsDisplay()
        
        delegate?.canvasUpdated()
    }
    
    // Get image from canvas and convert to MNIST image size
    func getImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: self.bounds.size)
        let image = renderer.image { ctx in
            self.drawHierarchy(in: self.bounds, afterScreenUpdates: true)
        }
        
        let newSize = CGRect(x: 0, y: 0, width: MNISTSize, height: MNISTSize)
        UIGraphicsBeginImageContext(CGSize(width: MNISTSize, height: MNISTSize))
        image.draw(in: newSize)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    func clearLines() {
        lines.removeAll()
        setNeedsDisplay()
    }
}

class BarChart: UIView {

    var gapRatio: Float = Float(0.5)
    var yMax: Float = 1
    
    var labels: [String]?
    var values: [Float] = [Float]() {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    func buildRects() -> [CGRect] {
        let baseY = self.bounds.height
        let width = CGFloat(self.bounds.width) / (CGFloat(values.count) * (1 + CGFloat(gapRatio)))
        let gap = width * CGFloat(gapRatio)
        var offset = gap / 2
        
        var rects = [CGRect]()
        
        for val in values {
            let prob = val / yMax
            
            let origin = CGPoint(x: offset, y: baseY * (1 - CGFloat(prob)))
            let size = CGSize(width: width, height: baseY * CGFloat(prob))
            
            rects.append(CGRect(origin: origin, size: size))
            
            offset += gap + width
        }
        return rects
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.setFillColor(barGreen.cgColor)
        
        let rects = self.buildRects()
        context.fill(rects)
        
        // Draw labels on bars if labels exist
        guard let numLabels = labels?.count else { return }
        if numLabels == rects.count {
            let style = NSMutableParagraphStyle()
            style.alignment = NSTextAlignment.center
            
            let textFontAttributes = [
                NSAttributedString.Key.paragraphStyle: style,
                NSAttributedString.Key.font: UIFont(name: "Helvetica-Bold", size: rects[0].width),
                NSAttributedString.Key.foregroundColor: UIColor.white
            ]
            
            for ind in 0..<numLabels {
                if rects[ind].height < rects[0].width { continue }
                let nsLabel = NSString(string: labels![ind])
                nsLabel.draw(in: rects[ind], withAttributes: textFontAttributes as [NSAttributedString.Key: Any])
            }
        }
    }
    
}
