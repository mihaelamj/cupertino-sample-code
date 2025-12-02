/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Primary view controller for the sample code project.
*/

import UIKit

class ViewController: UIViewController {

    @IBOutlet var ovalShape: OvalShapeView!
    @IBOutlet var roundRectShape: RoundrectShapeView!
    @IBOutlet var squareShape: ShapeView!
    @IBOutlet var triangleShape: TriangleShapeView!

    @IBOutlet var alphaControl: AlphaControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupButtons()
        
        // Set the alpha control's color, and add a pointer interaction.
        alphaControl.currentColor = UIColor.systemOrange
        alphaControl.addInteraction(UIPointerInteraction(delegate: self))
        
        setupShapeView(shapeView: ovalShape, color: UIColor.systemRed, label: "Lift")
        setupShapeView(shapeView: roundRectShape, color: UIColor.systemGreen, label: "Highlight")
        setupShapeView(shapeView: triangleShape, color: UIColor.systemGray, label: "Hover")
        setupShapeView(shapeView: squareShape, color: UIColor.systemBlue, label: "Automatic")
    }
    
    func setupButtons() {
        /** Turn on and provide pointer style providers for the four UIButtons in this view controller.
            For convenience reference the buttons by their view tag.
        */
        for tag in 1...5 {
            if let button = view.viewWithTag(tag) as? UIButton {
                /** Set the pointerStyleProvider on this button.
                    Note: When setting a provider, setting "isPointerInteractionEnabled" to true for this button is not necessary).
                */
                button.pointerStyleProvider = buttonProvider
            }
        }
    }
    
    func setupShapeView(shapeView: ShapeView, color: UIColor, label: String) {
        shapeView.backgroundColor = UIColor.clear
        shapeView.innerPathColor = color
        shapeView.effectName = label
        
        // Make the shape view movable.
        let panGestureRecognizer =
            UIPanGestureRecognizer(target: self, action: #selector(panShape(_:)))
        panGestureRecognizer.delegate = self
        shapeView.addGestureRecognizer(panGestureRecognizer)

        // Make this shape view tappable.
        // Note here we use a custom tap gesture recognizer for showing how to block a tap event.
        let tapGestureRecognizer =
            UITapGestureRecognizer(target: self, action: #selector(tapShape(_:)))
        tapGestureRecognizer.delegate = self // As the delegate we want to gate any particular event.
        shapeView.addGestureRecognizer(tapGestureRecognizer)

        // Make this shape grow and shrink with pinch.
        let pinchGestureRecognizer =
            UIPinchGestureRecognizer(target: self, action: #selector(scaleShape(_:)))
        shapeView.addGestureRecognizer(pinchGestureRecognizer)
        
        // Make this shape change when hovered over.
        let hoverGestureRecognizer =
            UIHoverGestureRecognizer(target: self, action: #selector(hoverShape(_:)))
        shapeView.addGestureRecognizer(hoverGestureRecognizer)

        // Set up pointer interaction on this view coordinated by this view controller.
        shapeView.addInteraction(UIPointerInteraction(delegate: self))
        
        /** Add a contextual menu to this shape.
            Contextual menu is opened by touchscreen touch and hold, trackpad two-finger button click, and control-click.
         */
        let contextMenuInteraction = UIContextMenuInteraction(delegate: self)
        shapeView.addInteraction(contextMenuInteraction)
    }
    
    // MARK: - UIGestureRecognizer
    
    func adjustAnchorPointForGestureRecognizer(gestureRecognizer: UIGestureRecognizer) {
        if gestureRecognizer.state == .began {
            if let shapeViewToUse = gestureRecognizer.view {
                let locationInView = gestureRecognizer.location(in: shapeViewToUse)
                let locationInSuperview = gestureRecognizer.location(in: shapeViewToUse.superview)
                shapeViewToUse.layer.anchorPoint =
                    CGPoint(x: locationInView.x / shapeViewToUse.bounds.size.width,
                            y: locationInView.y / shapeViewToUse.bounds.size.height)
                shapeViewToUse.center = locationInSuperview
            }
        }
    }
    
    @objc
    func panShape(_ gestureRecognizer: UIPanGestureRecognizer) {
        guard let shapeViewToUse = gestureRecognizer.view as? ShapeView else { return }

        func updateShapeView() {
            let translation = gestureRecognizer.translation(in: shapeViewToUse.superview)

            if gestureRecognizer.modifierFlags.contains(.command) {
                // Command key is down during pan, change the frame to orange.
                shapeViewToUse.viewPathColor = UIColor.systemOrange
                shapeViewToUse.setNeedsDisplay()
            }

            shapeViewToUse.center =
                CGPoint(x: shapeViewToUse.center.x + translation.x,
                        y: shapeViewToUse.center.y + translation.y)

            gestureRecognizer.setTranslation(CGPoint(), in: shapeViewToUse.superview)
        }

        switch gestureRecognizer.state {
        case .began:
            adjustAnchorPointForGestureRecognizer(gestureRecognizer: gestureRecognizer)
            updateShapeView()

        case .changed:
            updateShapeView()

        case .ended, .cancelled:
            // Reset the frame to yellow in case the user held down the command key.
            shapeViewToUse.viewPathColor = UIColor.systemYellow
            shapeViewToUse.setNeedsDisplay()

        default: break
        }
    }
    
    @objc
    func tapShape(_ gestureRecognizer: UITapGestureRecognizer) {
        if let shapeViewToUse = gestureRecognizer.view as? ShapeView {
            // User tapped within the view shape, bring it forward.
            view.bringSubviewToFront(shapeViewToUse)
        }
    }
    
    @objc
    func scaleShape(_ gestureRecognizer: UIPinchGestureRecognizer) {
        adjustAnchorPointForGestureRecognizer(gestureRecognizer: gestureRecognizer)
        
        if let pieceView = gestureRecognizer.view {
            if gestureRecognizer.state == .began || gestureRecognizer.state == .changed {
                pieceView.transform =
                    pieceView.transform.scaledBy(x: gestureRecognizer.scale,
                                                 y: gestureRecognizer.scale)
                gestureRecognizer.scale = 1
            }
        }
    }
    
    @objc
    func hoverShape(_ gestureRecognizer: UIHoverGestureRecognizer) {
        guard let shapeViewToUse = gestureRecognizer.view as? ShapeView else { return }

        switch gestureRecognizer.state {
        case .began, .changed:
            // User hovered within the view's path, change the view's border color.
            var pathViewColor = UIColor.systemTeal
            if gestureRecognizer.modifierFlags.contains(.command) {
                // If the command key is pressed while hovering change frame color to pink.
                pathViewColor = UIColor.systemPink
            }
            shapeViewToUse.viewPathColor = pathViewColor
            shapeViewToUse.setNeedsDisplay()

        case .ended, .cancelled:
            // User left the view, restore the border color.
            shapeViewToUse.restoreOuterFrameColor()

        default:
            break
        }
    }
    
}

// MARK: - UIGestureRecognizerDelegate

extension ViewController: UIGestureRecognizerDelegate {

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        let result = true

        if gestureRecognizer is UIPanGestureRecognizer {
            if let shapeViewToUse = gestureRecognizer.view as? ShapeView {
                // Bring the shape to front early, before the context menu might try to add a preview view.
                view.bringSubviewToFront(shapeViewToUse)
            }
        }
        return result
    }
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        var result = true
        if gestureRecognizer is UITapGestureRecognizer {
            // Block the tap gesture if the shift key is down.
            result = !gestureRecognizer.modifierFlags.contains(.shift)
        }
        return result
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // The default behavior that you'd get if this method weren't implemented.
        var result = false

        // Allow the pan gesture to recognize alongside gestures for the context menu.
        if gestureRecognizer is UIPanGestureRecognizer {
            result = true
        }

        return result
    }
}

