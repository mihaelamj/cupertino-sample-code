/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
NSControl subclass to show pointer interaction and scrolling with UIPanGestureRecognizer.
*/

import UIKit

class AlphaControl: UIControl {

    var currentColor = UIColor.gray
    var currentAlpha: CGFloat = 1.0
    
    // Identifier for this control's UIPointerInteraction region.
    static let regionIdentifier: AnyHashable = "colorPath"
    
    private let marginSpacing: CGFloat = 6.0
    private let cornerRadius: CGFloat = 12.0
    
    private var colorSwatch: UIView!
    private var colorLabel: UILabel!
    private var valueLabel: UILabel!
    
    // The bezier path region for the pointer shape highlight effect.
    var highlightRegion: UIBezierPath {
        // Make the highlight region from the control's bounds, but enlarge it a bit.
        let highlightBounds = bounds.insetBy(dx: -6.0, dy: -6.0)
        let path = UIBezierPath(roundedRect: highlightBounds, cornerRadius: cornerRadius)

        /* If you want a fancier highlight effect by highlighting just the label and color swatch use:
        let path = UIBezierPath()
        guard colorSwatch != nil && colorLabel != nil else { return path }

        let colorSwatchFrame = colorSwatch.frame.insetBy(dx: -10.0, dy: -10.0)
        path.append(UIBezierPath(roundedRect: colorSwatchFrame, cornerRadius: cornerRadius))

        var labelFrame = colorLabel.frame.insetBy(dx: -10.0, dy: -10.0)
        labelFrame.size.width += marginSpacing
        path.append(UIBezierPath(roundedRect: labelFrame, cornerRadius: 6.0))
        */
        return path
    }
    
    func commonInit(color: UIColor, label: String) {
        backgroundColor = UIColor.clear
        currentColor = color
        
        // Setup and add the color swatch label.
        colorLabel = UILabel(frame: CGRect())
        colorLabel.text = label
        colorLabel.sizeToFit()
        colorLabel.frame.origin.y = (frame.size.height - colorLabel.frame.size.height) / 2
        colorLabel.frame.origin.x += marginSpacing
        addSubview(colorLabel)

        // Setup and add the color swatch.
        let colorSwatchFrame =
            CGRect(x: colorLabel.bounds.width + marginSpacing * 2,
                   y: 0.0,
                   width: frame.width - colorLabel.bounds.width - marginSpacing * 2,
                   height: frame.height)
        colorSwatch = UIView(frame: colorSwatchFrame)
        let yLoc = (colorSwatchFrame.size.height - colorSwatch.frame.size.height) / 2
        colorSwatch.frame.origin.y = yLoc
        addSubview(colorSwatch)
        
        // Add a pan gesture to change the alpha of the color swatch color while panning with direct touch,
        // or two-finger scroll gesture with the trackpads.
        let panGestureRecognizer =
            UIPanGestureRecognizer(target: self, action: #selector(panColor(_:)))
        // We want continuous scrolls originated from devices like trackpads.
        panGestureRecognizer.allowedScrollTypesMask = [.continuous]
        colorSwatch.addGestureRecognizer(panGestureRecognizer)
        
        valueLabel = UILabel(frame: CGRect())
        valueLabel.frame.origin.x = (colorSwatch.bounds.width - valueLabel.bounds.size.width) / 2
        valueLabel.frame.origin.y = 10.0
        colorSwatch.addSubview(valueLabel)
        
        drawAlphaValue()
    }
    
    init(frame: CGRect, color: UIColor, label: String) {
        super.init(frame: frame)
        commonInit(color: color, label: label)
    }
   
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit(color: UIColor.gray, label: NSLocalizedString("ControlTitle", comment: ""))
    }
    
    func drawAlphaValue() {
        // Output the alpha value.
        valueLabel.text = String(format: "%1.2f", currentAlpha)
        valueLabel.sizeToFit()
        valueLabel.frame.origin.x = (colorSwatch.bounds.width - valueLabel.bounds.size.width) / 2
    }
    
    func targetedPreview() -> UITargetedPreview {
        let parameters = UIPreviewParameters()
        let visiblePath = highlightRegion
        parameters.visiblePath = visiblePath
        parameters.backgroundColor = UIColor.clear
        return UITargetedPreview(view: self, parameters: parameters)
    }

    override func draw(_ rect: CGRect) {
        // Draw the color swatch.
        let path = UIBezierPath(roundedRect: colorSwatch.frame, cornerRadius: cornerRadius)
        currentColor.setFill()
        path.fill()
        
        // Frame the color swatch.
        let newFramePath = path.bounds.insetBy(dx: 2.0, dy: 2.0)
        let framePath = UIBezierPath(roundedRect: newFramePath, cornerRadius: cornerRadius)
        UIColor.systemBlue.setStroke()
        
        var hue: CGFloat = 0.0, saturation: CGFloat = 0.0, brightness: CGFloat = 0.0, alpha: CGFloat = 0.0
        if currentColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) {
            let darkerColor =
                UIColor(hue: hue, saturation: saturation, brightness: brightness * 0.75, alpha: 1.0)
            darkerColor.setStroke()
            framePath.lineWidth = 4.0
            framePath.stroke()
        }
    }
    
    @objc
    /** Change the alpha of the current color while panning with direct touch,
        or two-finger scroll gesture with the trackpads.
    */
    func panColor(_ gestureRecognizer: UIPanGestureRecognizer) {
        let velocity = gestureRecognizer.velocity(in: colorSwatch)
        var hue: CGFloat = 0.0, saturation: CGFloat = 0.0, brightness: CGFloat = 0.0, alpha: CGFloat = 0.0
        if currentColor.getHue(&hue,
                               saturation: &saturation,
                               brightness: &brightness,
                               alpha: &alpha) {
            if velocity.x > 0 {
                // Pan gesture motion to the right.
                alpha += 0.01
                if alpha > 1 { alpha = 1 }
            } else {
                // Pan gesture motion to the left.
                alpha -= 0.01
                if alpha < 0 { alpha = 0 }
            }
            currentAlpha = alpha
            currentColor = UIColor(hue: hue,
                                   saturation: saturation,
                                   brightness: brightness,
                                   alpha: currentAlpha)
            drawAlphaValue()
            setNeedsDisplay()
        }
    }
    
}
